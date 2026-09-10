# frozen_string_literal: true

module ChatbotServices
  # Proyecta la liquidez disponible a una fecha futura, considerando el flujo neto
  # mensual de transacciones recurrentes y pagos obligatorios (recurrentes y unicos).
  class SavingsProjector
    MONTHS = {
      'enero' => 1, 'febrero' => 2, 'marzo' => 3, 'abril' => 4, 'mayo' => 5, 'junio' => 6,
      'julio' => 7, 'agosto' => 8, 'septiembre' => 9, 'octubre' => 10, 'noviembre' => 11, 'diciembre' => 12
    }.freeze

    MONTHLY_MULTIPLIERS = {
      'daily' => 30, 'weekly' => 4.33, 'bi_weekly' => 2.17, 'monthly' => 1,
      'bi_monthly' => 0.5, 'quarterly' => (1.0 / 3), 'semi_annually' => (1.0 / 6),
      'annually' => (1.0 / 12)
    }.freeze

    DEFAULT_HORIZON_MONTHS = 6
    INCOMPLETE_DATA_WARNING = 'No tienes pagos obligatorios registrados; ' \
                              'esta proyección podría no reflejar todos tus compromisos futuros.'

    def initialize(user:, message:)
      @user = user
      @message = message.to_s
    end

    def calculate
      Result.success(data: { result: result_hash, assumptions: assumptions, warnings: warnings })
    end

    # Publico: reutilizado por ChatbotServices::ScenarioSimulator para el escenario base.
    def monthly_net_flow
      recurring_income_total - recurring_expense_total - monthly_obligatory_total
    end

    private

    attr_reader :user, :message

    def result_hash
      months = months_between(Date.current, target_date)
      one_time = one_time_obligatory_total(target_date)

      {
        primary_metric: (current_liquidity + (monthly_net_flow * months) - one_time).round(2),
        breakdown: breakdown_for(months, one_time)
      }
    end

    def breakdown_for(months, one_time)
      [
        { label: 'Liquidez actual', amount: current_liquidity.round(2) },
        { label: 'Flujo neto mensual estimado', amount: monthly_net_flow.round(2) },
        { label: 'Meses proyectados', amount: months },
        { label: 'Pagos obligatorios únicos en el periodo', amount: -one_time.round(2) }
      ]
    end

    def assumptions
      net_flow_note = 'El flujo neto mensual se calcula con transacciones recurrentes ' \
                       'activas y pagos obligatorios recurrentes.'
      ["Fecha objetivo proyectada: #{target_date.strftime('%d/%m/%Y')}.", net_flow_note]
    end

    def warnings
      user.obligatory_payments.none? ? [INCOMPLETE_DATA_WARNING] : []
    end

    def current_liquidity
      @current_liquidity ||= SavingGoalServices::ProgressCalculator.new(user).total_available_money.to_f
    end

    def explicit_date?
      message.match?(/\d{4}/) || MONTHS.keys.any? { |m| message.downcase.include?(m) }
    end

    def target_date
      @target_date ||= explicit_date? ? date_from_message : DEFAULT_HORIZON_MONTHS.months.from_now.to_date
    end

    def date_from_message
      year = message[/(20\d{2})/, 1]&.to_i || Date.current.year
      month_name = MONTHS.keys.find { |m| message.downcase.include?(m) }
      month_name ? Date.new(year, MONTHS[month_name], 1).end_of_month : Date.new(year, 12, 31)
    end

    def months_between(from, to)
      ((to.year - from.year) * 12 + (to.month - from.month)).clamp(1, 120)
    end

    def recurring_income_total
      monthly_recurring_total('income')
    end

    def recurring_expense_total
      monthly_recurring_total('expense')
    end

    def monthly_recurring_total(type_code)
      type_id = Catalog.by_group_and_code('transaction_types', type_code)&.id
      return 0.0 if type_id.nil?

      user.recurring_transactions.active
          .where("transaction_options->>'transaction_type_id' = ?", type_id.to_s)
          .sum { |rt| rt.transaction_options['amount'].to_f * MONTHLY_MULTIPLIERS.fetch(rt.frequency, 1) }
    end

    def monthly_obligatory_total
      user.obligatory_payments.recurring.sum do |payment|
        monthly_equivalent(payment.amount.to_f, payment.get_recurrence)
      end
    end

    def monthly_equivalent(amount, recurrence)
      return 0.0 if recurrence.nil?

      case recurrence.frequency_type.code
      when 'daily' then amount * 30 / recurrence.frequency_value
      when 'weekly' then amount * 4.33 / recurrence.frequency_value
      when 'biweekly' then amount * 2.17
      when 'monthly' then amount / recurrence.frequency_value
      when 'yearly' then amount / 12.0 / recurrence.frequency_value
      else 0.0
      end
    end

    def one_time_obligatory_total(target)
      user.obligatory_payments.one_time.where(due_date: Date.current..target).sum(:amount).to_f
    end
  end
end
