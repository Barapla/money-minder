# frozen_string_literal: true

module ChatbotServices
  # Proyecta la liquidez disponible a una fecha futura, considerando el flujo neto
  # mensual de transacciones recurrentes y pagos obligatorios (recurrentes y unicos).
  class SavingsProjector # rubocop:disable Metrics/ClassLength
    MONTHS = {
      'enero' => 1, 'febrero' => 2, 'marzo' => 3, 'abril' => 4, 'mayo' => 5, 'junio' => 6,
      'julio' => 7, 'agosto' => 8, 'septiembre' => 9, 'octubre' => 10, 'noviembre' => 11, 'diciembre' => 12
    }.freeze

    DEFAULT_HORIZON_MONTHS = 6
    AGUINALDO_NOTE = 'El aguinaldo es proporcional al tiempo trabajado en el año ' \
                     '(15 días de ley) y no forma parte del flujo mensual.'
    # Se avisa porque la fecha de entrega la pone cada empresa, y porque la app no
    # lleva el saldo de esta prestacion por ningun lado.
    SAVINGS_FUND_NOTE = 'El fondo de ahorro de nómina es lo acumulado entre tu ' \
                        'aportación y la del patrón; la fecha en que te lo entregan ' \
                        'depende de tu empresa y no se registra en la app.'
    INCOMPLETE_DATA_WARNING = 'No tienes pagos obligatorios registrados; ' \
                              'esta proyección podría no reflejar todos tus compromisos futuros.'

    def initialize(user:, message:)
      @user = user
      @message = message.to_s
    end

    def calculate
      Result.success(data: { result: result_hash, assumptions: assumptions, warnings: warnings })
    end

    private

    attr_reader :user, :message

    def result_hash
      months = months_between(Date.current, target_date)
      one_time = one_time_obligatory_total(target_date)

      {
        # Etiquetado explicito: "primary_metric" a secas no le decia nada al
        # modelo y rehacia la cuenta por su lado (llegó a usar 1 mes en vez de 3).
        metric_label: "Total proyectado al #{target_date.strftime('%d/%m/%Y')}",
        primary_metric: projected_total(months, one_time),
        formula: formula_text(months, one_time),
        # Fuera del desglose a proposito: el desglose son cifras que SUMAN al
        # total, y esta es una tasa. Mezclarlas fue lo que hizo que el modelo
        # rehiciera la cuenta con el numero de meses equivocado.
        monthly_net_flow: monthly_net_flow.round(2),
        months_projected: months,
        breakdown: breakdown_for(months, one_time)
      }
    end

    # Los meses van aparte del desglose de dinero: mezclarlos en la misma lista de
    # `amount` hacia que se leyeran como pesos.
    def breakdown_for(months, one_time)
      rows = [
        { label: 'Liquidez actual', amount: current_liquidity.round(2), unit: 'MXN' },
        { label: "Flujo neto mensual x #{months} meses",
          amount: (monthly_net_flow * months).round(2), unit: 'MXN' },
        { label: 'Pagos obligatorios únicos en el periodo', amount: -one_time.round(2), unit: 'MXN' }
      ]
      rows << aguinaldo_row if aguinaldo_amount.positive?
      rows << savings_fund_row if savings_fund_accrued.positive?
      rows
    end

    def projected_total(months, one_time)
      (current_liquidity + (monthly_net_flow * months) - one_time +
        aguinaldo_amount + savings_fund_accrued).round(2)
    end

    def formula_text(months, one_time)
      parts = ["#{current_liquidity.round(2)} de liquidez",
               "+ #{monthly_net_flow.round(2)} x #{months} meses de flujo"]
      parts.concat(extra_formula_parts(one_time))
      "#{parts.join(' ')} = #{projected_total(months, one_time)}"
    end

    def extra_formula_parts(one_time)
      parts = []
      parts << "- #{one_time.round(2)} de pagos únicos" if one_time.positive?
      parts << "+ #{aguinaldo_amount.round(2)} de aguinaldo" if aguinaldo_amount.positive?
      parts << "+ #{savings_fund_accrued.round(2)} de fondo de ahorro" if savings_fund_accrued.positive?
      parts
    end

    def aguinaldo_row
      { label: "Aguinaldo #{target_date.year} (extra, no está en el flujo mensual)",
        amount: aguinaldo_amount.round(2), unit: 'MXN' }
    end

    def savings_fund_row
      { label: 'Fondo de ahorro de nómina acumulado (tu parte + la del patrón)',
        amount: savings_fund_accrued.round(2), unit: 'MXN' }
    end

    # El fondo de ahorro de NOMINA no es ninguno de los budgets savings_fund del
    # usuario (esos son sus Sofipos) ni esta en el flujo: la parte del empleado se
    # descuenta del neto y la del patron nunca toca la cuenta. Es dinero suyo que
    # la app no ve por ningun lado, asi que se calcula aqui.
    def savings_fund_accrued
      @savings_fund_accrued ||= calculate_savings_fund
    end

    def calculate_savings_fund
      profile = user.payroll_profile
      employment = user.employment_information
      return 0.0 unless profile && employment

      result = Payroll::SavingsFundCalculator.new(
        monthly_gross_salary: profile.base_salary,
        savings_fund_percentage: profile.savings_fund_rate
      ).call
      return 0.0 unless result.success?

      (result.data[:monthly_total].to_f * accrual_months(employment.start_date)).round(2)
    end

    # Meses acumulados desde que entro, dentro del periodo anual en curso.
    def accrual_months(hire_date)
      period_start = [hire_date, Date.new(target_date.year, 1, 1)].max
      return 0.0 if target_date < period_start

      ((target_date - period_start).to_i / 30.4).round(2)
    end

    # El aguinaldo es un extra anual que NO vive en el flujo mensual. Se suma
    # aqui, calculado, en vez de esperar a que el modelo lo sume solo: cuando se
    # le dejaba a el, lo daba por incluido y no lo sumaba.
    def aguinaldo_amount
      @aguinaldo_amount ||= calculate_aguinaldo
    end

    def calculate_aguinaldo
      return 0.0 unless target_date >= Date.new(target_date.year, 12, 1)
      return 0.0 unless user.employment_information && user.payroll_profile

      result = aguinaldo_result
      result.success? ? result.data[:amount].to_f : 0.0
    end

    def aguinaldo_result
      Payroll::AguinaldoCalculator.new(
        monthly_gross_salary: user.payroll_profile.base_salary,
        hire_date: user.employment_information.start_date,
        calculation_date: target_date
      ).call
    end

    def assumptions
      net_flow_note = 'El flujo neto mensual se calcula con transacciones recurrentes ' \
                       'activas y pagos obligatorios recurrentes.'
      notes = ["Fecha objetivo proyectada: #{target_date.strftime('%d/%m/%Y')}.", net_flow_note]
      notes << AGUINALDO_NOTE if aguinaldo_amount.positive?
      notes << SAVINGS_FUND_NOTE if savings_fund_accrued.positive?
      notes
    end

    def warnings
      user.obligatory_payments.none? ? [INCOMPLETE_DATA_WARNING] : []
    end

    def current_liquidity
      @current_liquidity ||= LiquidityServices::Calculator.new(user).total_available_money.to_f
    end

    def monthly_net_flow
      @monthly_net_flow ||= ChatbotServices::NetFlowCalculator.new(user).monthly_net_flow
    end

    # Delegado a HorizonParser para que el calculador y la foto que se le manda a
    # Claude proyecten a la misma fecha.
    def target_date
      @target_date ||= ChatbotServices::HorizonParser.new(message).call_or_default
    end

    def months_between(from, to)
      ((to.year - from.year) * 12 + (to.month - from.month)).clamp(1, 120)
    end

    def one_time_obligatory_total(target)
      user.obligatory_payments.one_time.where(due_date: Date.current..target).sum(:amount).to_f
    end
  end
end
