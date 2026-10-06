# frozen_string_literal: true

module ChatbotServices
  # La foto financiera que se le manda a Claude en TODA consulta, sin importar
  # que calculador se haya elegido.
  #
  # Existe por dos fallas que se veian en las respuestas:
  #   1. Cada calculador armaba su propia base, asi que dos respuestas seguidas
  #      se contradecian en el patrimonio.
  #   2. La nomina no aparecia por ningun lado. No es un ObligatoryPayment: se
  #      genera al vuelo desde EmploymentInformation + PayrollProfile (FEAT-007),
  #      asi que "ingresos programados" solo veia los recordatorios sueltos y
  #      concluia que el usuario gasta mucho mas de lo que gana.
  class FinancialSnapshot
    def initialize(user, horizon_date: nil)
      @user = user
      @horizon_date = horizon_date
    end

    # Una sola instruccion, sin excepciones: la version larga traia dos reglas
    # opuestas ("la nomina ya esta incluida" / "el aguinaldo es extra") y el
    # modelo las confundia, dando por incluido el aguinaldo que no lo estaba.
    # Ahora el calculador ya suma todo y aqui solo se prohibe recalcular.
    OVERLAP_NOTE = 'CÓMO USAR ESTO: es contexto de apoyo para tu explicación. ' \
                   'Las cifras del cálculo adjunto ya están completas y no se ' \
                   'solapan con estas: no sumes ni restes nada de aquí encima.'

    def to_prompt
      sections = [balance_section, payroll_section, year_end_section, reminders_section]
      body = sections.compact
      return '' if body.empty?

      (body + [OVERLAP_NOTE]).join("\n")
    end

    # ── Saldos ───────────────────────────────────────────────────────────────

    def balance_section
      calc = LiquidityServices::Calculator.new(user)
      "SALDOS HOY (#{I18n.l(Date.current, format: :long)}): " \
        "patrimonio neto #{money(calc.total_available_money)}, " \
        "efectivo #{money(calc.cash_balance)}, débito #{money(calc.debit_balance)}, " \
        "fondos de ahorro #{money(calc.savings_balance)}, " \
        "deuda de tarjetas #{money(-calc.credit_debt.to_f)}."
    end

    # ── Nomina ───────────────────────────────────────────────────────────────

    def payroll_reminders
      return [] unless employment && profile

      @payroll_reminders ||= PayrollServices::ReminderGenerator
                             .new(user)
                             .generate(from_date: Date.current, to_date: horizon_date)
    end

    def payroll_total
      payroll_reminders.sum { |reminder| reminder.net_amount.to_f }
    end

    def payroll_section
      return nil if payroll_reminders.empty?

      'NÓMINA (lo que NO está en los recordatorios, se genera desde tu empleo): ' \
        "#{payroll_reminders.size} pagos de aquí al #{I18n.l(horizon_date, format: :long)} " \
        "por #{money(payroll_total)} netos en total. " \
        "Ingresaste el #{I18n.l(employment.start_date, format: :long)}, " \
        "sueldo base #{money(profile.base_salary)} mensual."
    end

    # ── Aguinaldo y fondo de ahorro ──────────────────────────────────────────

    def aguinaldo
      return nil unless employment && profile

      @aguinaldo ||= Payroll::AguinaldoCalculator.new(
        monthly_gross_salary: profile.base_salary,
        hire_date: employment.start_date,
        calculation_date: horizon_date
      ).call
    end

    def savings_fund
      return nil unless profile

      @savings_fund ||= Payroll::SavingsFundCalculator.new(
        monthly_gross_salary: profile.base_salary,
        savings_fund_percentage: profile.savings_fund_rate
      ).call
    end

    def year_end_section
      parts = [aguinaldo_line, savings_fund_line].compact
      return nil if parts.empty?

      "PRESTACIONES: #{parts.join(' ')}"
    end

    # ── Recordatorios ────────────────────────────────────────────────────────

    def reminders_section
      summary = ScheduledRemindersSummary.new(user)
      income = summary.scheduled_income_total
      payment = summary.scheduled_payment_total
      return nil if income.zero? && payment.zero?

      'RECORDATORIOS DE ESTE MES (aparte de la nómina): cobros programados ' \
        "#{money(income)}, pagos programados #{money(payment)}."
    end

    private

    attr_reader :user

    # Sin horizonte explicito se proyecta a fin de año, que es el periodo del que
    # se suele preguntar (aguinaldo, cierre).
    def horizon_date
      @horizon_date || Date.current.end_of_year
    end

    def employment
      return @employment if defined?(@employment)

      @employment = user.employment_information
    end

    def profile
      return @profile if defined?(@profile)

      @profile = user.payroll_profile
    end

    def aguinaldo_line
      return nil unless aguinaldo&.success?

      data = aguinaldo.data
      "aguinaldo #{data[:year]} #{money(data[:amount])} " \
        "(#{PayrollConstants[:aguinaldo_days]} días de ley, #{data[:days_worked]} de #{data[:days_in_year]} " \
        "días trabajados#{data[:proportional] ? ', proporcional' : ''})."
    end

    def savings_fund_line
      return nil unless savings_fund&.success?

      data = savings_fund.data
      "fondo de ahorro #{money(data[:employee_contribution])} tuyo más " \
        "#{money(data[:employer_contribution])} del patrón al mes " \
        "(#{money(data[:monthly_total])} mensual)."
    end

    def money(amount)
      ActiveSupport::NumberHelper.number_to_currency(amount.to_f, unit: '$')
    end
  end
end
