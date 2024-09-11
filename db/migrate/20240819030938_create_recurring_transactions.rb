# frozen_string_literal: true

# CreateRecurringTransactions Class
class CreateRecurringTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :recurring_transactions do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.decimal :amount
      t.text :description
      t.integer :transaction_type
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :currency, null: false, foreign_key: true
      t.integer :frequency
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    add_index :recurring_transactions, :uuid, unique: true
  end
end