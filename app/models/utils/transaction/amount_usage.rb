# frozen_string_literal: true

# Utils
module Utils
  # Transaction module
  module Transaction
    # AmountUsage module
    module AmountUsage
      extend ActiveSupport::Concern

      def used_percentage
        ((amount / pre_amount.to_f) * 100).round(2)
      end

      def spent_amount_by_category
        budget.transactions
              .joins(:transaction_type)
              .joins(:category)
              .where(category:)
              .where(transaction_type: { code: %w[expense transfer] })
              .sum(:amount)
      end

      def spent_amount_the_month_by_category
        budget.transactions
              .joins(:transaction_type)
              .joins(:category)
              .where(category:)
              .where('transaction_date >= ?', transaction_date.beginning_of_month)
              .where('transaction_date <= ?', transaction_date.end_of_month)
              .where(transaction_type: { code: %w[expense transfer] })
              .sum(:amount)
      end

      def earned_amount_the_month_by_category
        budget.transactions
              .joins(:transaction_type)
              .joins(:category)
              .where(category:)
              .where('transaction_date >= ?', transaction_date.beginning_of_month)
              .where('transaction_date <= ?', transaction_date.end_of_month)
              .where(transaction_type: { code: 'income' })
              .sum(:amount)
      end
    end
  end
end
