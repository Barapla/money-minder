# frozen_string_literal: true

module ChatbotServices
  # Flujo neto mensual estimado: ingresos recurrentes - gastos recurrentes - pagos
  # obligatorios recurrentes. Compartido por SavingsProjector y ScenarioSimulator para
  # no duplicar el calculo del escenario base (FEAT-031).
  class NetFlowCalculator
    MONTHLY_MULTIPLIERS = {
      'daily' => 30, 'weekly' => 4.33, 'bi_weekly' => 2.17, 'monthly' => 1,
      'bi_monthly' => 0.5, 'quarterly' => (1.0 / 3), 'semi_annually' => (1.0 / 6),
      'annually' => (1.0 / 12)
    }.freeze

    def initialize(user)
      @user = user
    end

    def monthly_net_flow
      recurring_income_total - recurring_expense_total - monthly_obligatory_total
    end

    private

    attr_reader :user

    def recurring_income_total
      monthly_recurring_total('income')
    end

    def recurring_expense_total
      monthly_recurring_total('expense')
    end

    # Suma en base de datos (CASE por frecuencia) en vez de cargar todas las
    # recurring_transactions en memoria para iterarlas con #sum.
    def monthly_recurring_total(type_code)
      type_id = Catalog.by_group_and_code('transaction_types', type_code)&.id
      return 0.0 if type_id.nil?

      user.recurring_transactions.active
          .where("transaction_options->>'transaction_type_id' = ?", type_id.to_s)
          .sum(Arel.sql("(transaction_options->>'amount')::numeric * (#{multiplier_case_sql})")).to_f
    end

    def multiplier_case_sql
      cases = MONTHLY_MULTIPLIERS.map do |freq, mult|
        "WHEN #{RecurringTransaction.frequencies.fetch(freq)} THEN #{mult}"
      end.join(' ')
      "CASE frequency #{cases} ELSE 1 END"
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
  end
end
