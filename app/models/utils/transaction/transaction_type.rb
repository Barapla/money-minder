# frozen_string_literal: true

# Utils
module Utils
  # Transaction module
  module Transaction
    # AmountUsage module
    module TransactionType
      extend ActiveSupport::Concern

      def negative_transaction?
        expense? || transfer?
      end

      def transfer?
        transaction_type&.code == 'transfer'
      end

      def income?
        transaction_type&.code == 'income'
      end

      def income_transfer?
        income? && related_transaction.present?
      end

      def expense?
        transaction_type&.code == 'expense'
      end
    end
  end
end
