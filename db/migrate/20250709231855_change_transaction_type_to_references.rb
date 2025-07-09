# frozen_string_literal: true

# This migration changes the transaction_type column in the transactions table
class ChangeTransactionTypeToReferences < ActiveRecord::Migration[7.0]
  def up
    # Remove the old transaction_type column
    remove_column :transactions, :transaction_type, :string

    # Add a new transaction_type_id column as a foreign key reference to transaction_types
    add_reference :transactions, :transaction_type,
                  null: false,
                  foreign_key: { to_table: :catalogs, name: 'fk_transactions_transaction_type' }
  end

  def down
    # Remove the new transaction_type_id column
    remove_reference :transactions, :transaction_type,
                     foreign_key: { to_table: :catalogs, name: 'fk_transactions_transaction_type' }

    # Add back the old transaction_type column
    add_column :transactions, :transaction_type, :string, null: false
  end
end
