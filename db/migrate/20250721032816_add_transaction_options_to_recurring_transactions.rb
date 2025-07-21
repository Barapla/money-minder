# frozen_string_literal: true

# Migration to add transaction options to RecurringTransactions
class AddTransactionOptionsToRecurringTransactions < ActiveRecord::Migration[7.0]
  def up
    add_column :recurring_transactions, :transaction_options, :jsonb, default: {}
  end

  def down
    remove_column :recurring_transactions, :transaction_options, :jsonb
  end
end
