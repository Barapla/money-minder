# frozen_string_literal: true

# Migration to remove transaction_id from RecurringTransactions
class RemoveTransactionIdFromRecurringTransactions < ActiveRecord::Migration[7.0]
  def up
    remove_reference :recurring_transactions, :transaction,
                     foreign_key: { to_table: :transactions,
                                    name: 'fk_transaction_recurring_transactions' }
  end

  def down
    add_reference :recurring_transactions, :transaction, null: false,
                                                         foreign_key: { to_table: :transactions,
                                                                        name: 'fk_transaction_recurring_transactions' }
  end
end
