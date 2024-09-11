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
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :currency, null: false, foreign_key: true
      t.date :transaction_date

      t.timestamps
    end

    add_index :transactions, :uuid, unique: true
  end
end