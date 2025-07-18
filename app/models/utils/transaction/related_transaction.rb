# frozen_string_literal: true

# Utils
module Utils
  # Transaction module
  module Transaction
    # TransactionHistory module
    module RelatedTransaction
      extend ActiveSupport::Concern

      included do
        after_create :create_related_transaction, if: :transfer?
      end

      private

      def create_related_transaction
        new_transaction_type = ::Catalog.by_group_and_code('transaction_types', 'income')

        ::Transaction.create(
          budget: related_budget,
          related_budget: budget,
          transaction_type: new_transaction_type,
          amount:,
          description:,
          category:,
          transaction_date:,
          icon:,
          color:,
          user:
        )
      end
    end
  end
end
