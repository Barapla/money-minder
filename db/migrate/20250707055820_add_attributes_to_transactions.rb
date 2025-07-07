# frozen_string_literal: true

# This migration adds references to related budget and related transaction in the transactions table.
class AddAttributesToTransactions < ActiveRecord::Migration[7.0]
  def up
    add_reference :transactions, :related_budget,
                  foreign_key: { to_table: :budgets, name: 'fk_transactions_related_budget' }
    add_reference :transactions, :related_transaction,
                  foreign_key: { to_table: :transactions, name: 'fk_transactions_related_transaction' }
  end

  def down
    remove_reference :transactions, :related_budget,
                     foreign_key: { to_table: :budgets, name: 'fk_transactions_related_budget' }
    remove_reference :transactions, :related_transaction,
                     foreign_key: { to_table: :transactions, name: 'fk_transactions_related_transaction' }
  end
end
