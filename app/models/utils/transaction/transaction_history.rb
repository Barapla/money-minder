# frozen_string_literal: true

# Utils
module Utils
  # Transaction module
  module Transaction
    # TransactionHistory module
    module TransactionHistory
      extend ActiveSupport::Concern

      included do
        after_create :create_transaction_history, :update_budget_amount
        after_update :update_transaction_history, if: :saved_change_to_amount?
        before_destroy :return_budget_amount
      end

      def pre_amount
        transaction_history&.pre_amount
      end

      def post_amount
        transaction_history&.post_amount
      end

      private

      def create_transaction_history
        post_amount = calculate_post_amount(budget.current_amount)

        ::TransactionHistory.create(
          transaction_record: self,
          pre_amount: budget.current_amount,
          post_amount:
        )
      end

      def update_budget_amount
        budget.update(current_amount: post_amount)
      end

      def return_budget_amount
        new_current_amount = negative_transaction? ? budget.current_amount + amount : budget.current_amount - amount

        budget.update(current_amount: new_current_amount)
      end

      def update_transaction_history
        post_amount_history = post_amount
        new_post_amount = calculate_post_amount(pre_amount)

        transaction_history.update(
          pre_amount:,
          post_amount: new_post_amount
        )
        update_budget_difference_amount(post_amount_history, new_post_amount)
      end

      def calculate_post_amount(pre_amount)
        negative_transaction? ? pre_amount - amount : pre_amount + amount
      end

      def update_budget_difference_amount(old_amount, new_amount)
        difference = old_amount - new_amount
        budget.update(current_amount: budget.current_amount - difference)
      end
    end
  end
end
