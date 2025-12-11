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

      def update_credit_card_cycle
        credit_card = budget.credit_card
        return unless credit_card

        # Encontrar el ciclo correspondiente a la fecha de la transacción
        target_cycle = credit_card.determine_cycle_for_transaction(self)

        # Procesar la transacción en el ciclo
        target_cycle.process_transaction(self)
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

        update_credit_card_cycle if budget.budget_type&.code == 'credit_card'
      end

      def return_budget_amount
        new_current_amount = negative_transaction? ? budget.current_amount + amount : budget.current_amount - amount
        budget.update(current_amount: new_current_amount)

        # Revertir cambios en el ciclo de tarjeta de crédito
        revert_credit_card_cycle if budget.budget_type&.code == 'credit_card'
      end

      def update_transaction_history
        post_amount_history = post_amount
        new_post_amount = calculate_post_amount(pre_amount)

        transaction_history.update(
          pre_amount:,
          post_amount: new_post_amount
        )
        update_budget_difference_amount(post_amount_history, new_post_amount)
        update_credit_card_cycle_on_change if budget.budget_type&.code == 'credit_card'
      end

      def calculate_post_amount(pre_amount)
        negative_transaction? ? pre_amount - amount : pre_amount + amount
      end

      def update_budget_difference_amount(old_amount, new_amount)
        difference = old_amount - new_amount
        budget.update(current_amount: budget.current_amount - difference)
      end

      def revert_credit_card_cycle
        credit_card = budget.credit_card
        return unless credit_card

        target_cycle = credit_card.determine_cycle_for_transaction(self)

        if negative_transaction?
          target_cycle.closing_balance += amount
          target_cycle.purchases -= amount
        else
          target_cycle.closing_balance -= amount # Revertir pago (quitar la reducción)
          target_cycle.purchases -= amount
        end

        target_cycle.save!
      end

      def update_credit_card_cycle_on_change
        credit_card = budget.credit_card
        target_cycle = credit_card.determine_cycle_for_transaction(self)

        # Revertir monto anterior
        old_amount = amount_before_last_save
        if negative_transaction?
          target_cycle.closing_balance += old_amount
          target_cycle.purchases -= old_amount
        else
          target_cycle.closing_balance += old_amount
          target_cycle.payments -= old_amount
        end
        # Aplicar nuevo monto
        target_cycle.process_transaction(self)
      end
    end
  end
end
