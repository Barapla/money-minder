# frozen_string_literal: true

module Utils
  # BudgetAttributes module
  module BudgetAttributes
    def limit_amount
      budget_type&.code == 'credit_card' ? credit_card&.limit_amount : 0.0
    end
  end
end
