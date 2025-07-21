# frozen_string_literal: true

# Utils
module Utils
  # Transaction module
  module Transaction
    # TransactionHistory module
    module RelatedTransaction
      extend ActiveSupport::Concern

      included do
        belongs_to :related_parent, class_name: 'Transaction',
                                    foreign_key: 'related_transaction_id', optional: true

        has_one :related_child, class_name: 'Transaction',
                                foreign_key: 'related_transaction_id', dependent: :destroy

        after_create :create_related_transaction, if: :transfer?
      end

      def related_transaction
        related_child || related_parent
      end

      private

      def create_related_transaction
        new_transaction_type = ::Catalog.by_group_and_code('transaction_types', 'income')

        params = transaction_params.merge(budget: related_budget,
                                          related_budget: budget,
                                          transaction_type: new_transaction_type,
                                          related_transaction_id: id)

        ::Transaction.create(params)
      end

      def transaction_params
        {
          amount:,
          description:,
          category:,
          transaction_date:,
          icon:,
          color:,
          user:
        }
      end
    end
  end
end
