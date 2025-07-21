# frozen_string_literal: true

# Migration to remove fields from RecurringTransactions
class RemoveFieldsToRecurringTransactionsFromTransactions2 < ActiveRecord::Migration[7.0]
  def up
    remove_column :recurring_transactions, :amount, :decimal
    remove_column :recurring_transactions, :description, :string
  end

  def down
    add_column :recurring_transactions, :amount, :decimal, null: false, default: 0.0
    add_column :recurring_transactions, :description, :string
  end
end
