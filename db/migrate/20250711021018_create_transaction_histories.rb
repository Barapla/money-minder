# frozen_string_literal: true

# CreateTransactionHistories Class
class CreateTransactionHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :transaction_histories do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :transaction, null: false,
                                 foreign_key: { to_table: :transactions, name: 'fk_transaction_histories_transactions' }
      t.decimal :pre_amount
      t.decimal :post_amount

      t.timestamps
    end

    add_index :transaction_histories, :uuid, unique: true
  end
end
