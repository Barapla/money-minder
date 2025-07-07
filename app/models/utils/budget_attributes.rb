# frozen_string_literal: true

module Utils
  # BudgetAttributes module
  module BudgetAttributes
    def limit_amount
      budget_type&.code == 'credit_card' ? credit_card&.limit_amount : 0.0
    end

    def debt_amount
      budget_type&.code == 'credit_card' ? credit_card&.debt_amount : 0.0
    end

    def payday
      budget_type&.code == 'credit_card' ? credit_card&.payday : nil
    end

    def cutting_day
      budget_type&.code == 'credit_card' ? credit_card&.cutting_day : nil
    end
  end
end
