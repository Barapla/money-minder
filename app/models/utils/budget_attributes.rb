# frozen_string_literal: true

module Utils
  # BudgetAttributes module
  module BudgetAttributes
    def limit_amount
      budget_type&.code == 'credit_card' ? credit_card&.limit_amount : 0.0
    end

    def debt_amount
      return 0.0 unless budget_type&.code == 'credit_card'

      return 0.0 unless credit_card.persisted?

      credit_card.current_debt || 0.0
    end

    def payday
      return nil unless budget_type&.code == 'credit_card'

      credit_card&.current_cycle&.payment_due_date
    end

    def cutting_day
      return nil unless budget_type&.code == 'credit_card'

      credit_card&.current_cycle&.cutting_date
    end
  end
end
