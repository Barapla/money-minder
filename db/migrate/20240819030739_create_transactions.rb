# frozen_string_literal: true

# CreateTransactions Class
class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.decimal :amount
      t.text :description
      t.integer :transaction_type
      t.references :category, null: false, foreign_key: { to_table: :categories, name: 'fk_transactions_category' }
      t.references :user, null: false, foreign_key: { to_table: :users, name: 'fk_transactions_user' }
      t.references :currency, null: false, foreign_key: { to_table: :currencies, name: 'fk_transactions_currency' }
      t.date :transaction_date

      t.timestamps
    end

    add_index :transactions, :uuid, unique: true
  end
end
