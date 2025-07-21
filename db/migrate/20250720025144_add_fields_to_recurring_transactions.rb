# frozen_string_literal: true

# Migration to add fields to RecurringTransactions
class AddFieldsToRecurringTransactions < ActiveRecord::Migration[7.0]
  def up
    add_reference :recurring_transactions, :transaction, null: false,
                                                         foreign_key: { to_table: :transactions,
                                                                        name: 'fk_transaction_recurring_transactions' }
    add_column :recurring_transactions, :next_execution_date, :date
    add_column :recurring_transactions, :status, :integer, default: 0
    add_column :recurring_transactions, :execution_count, :integer, default: 0
    add_column :recurring_transactions, :max_executions, :integer
    add_column :recurring_transactions, :tags, :text
    add_column :recurring_transactions, :auto_approve, :boolean, default: true
  end

  def down
    remove_reference :recurring_transactions, :transaction,
                     foreign_key: { to_table: :transactions,
                                    name: 'fk_transaction_recurring_transactions' }
    remove_column :recurring_transactions, :next_execution_date, :date
    remove_column :recurring_transactions, :status, :integer
    remove_column :recurring_transactions, :execution_count, :integer
    remove_column :recurring_transactions, :max_executions, :integer
    remove_column :recurring_transactions, :tags, :text
    remove_column :recurring_transactions, :auto_approve, :boolean
  end
end
