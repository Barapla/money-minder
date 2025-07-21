# frozen_string_literal: true

# Migration to remove fields from RecurringTransactions
class RemoveFieldsToRecurringTransactionsFromTransaction < ActiveRecord::Migration[7.0]
  def up
    remove_column :recurring_transactions, :transaction_type, :string
    remove_reference :recurring_transactions, :category,
                     foreign_key: { to_table: :categories, name: 'fk_recurring_transactions_category' }
    remove_reference :recurring_transactions, :currency,
                     foreign_key: { to_table: :currencies, name: 'fk_recurring_transactions_currency' }
  end

  def down
    add_column :recurring_transactions, :transaction_type, :string
    add_reference :recurring_transactions, :category, null: false,
                                                      foreign_key: { to_table: :categories,
                                                                     name: 'fk_recurring_transactions_category' }
    add_reference :recurring_transactions, :currency, null: false,
                                                      foreign_key: { to_table: :currencies,
                                                                     name: 'fk_recurring_transactions_currency' }
  end
end
