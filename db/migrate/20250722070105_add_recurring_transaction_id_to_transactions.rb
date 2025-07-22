# frozen_string_literal: true

# Migration to add transaction options to RecurringTransactions
class AddRecurringTransactionIdToTransactions < ActiveRecord::Migration[7.0]
  def up
    add_reference :transactions, :recurring_transaction, null: true,
                                                         foreign_key: { to_table: :recurring_transactions,
                                                                        name: 'fk_recurring_transaction_transactions' }
  end

  def down
    remove_reference :transactions, :recurring_transaction,
                     foreign_key: { to_table: :recurring_transactions,
                                    name: 'fk_recurring_transaction_transactions' }
  end
end
