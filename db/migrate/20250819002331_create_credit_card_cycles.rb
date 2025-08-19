# frozen_string_literal: true

# CreateCreditCardCycles Class
class CreateCreditCardCycles < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_card_cycles do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :credit_card, null: false, foreign_key: { to_table: :credit_cards, name: 'fk_credit_card_cycles_credit_card' }
      t.date :cutting_date
      t.date :payment_due_date
      t.decimal :statement_balance, precision: 10, scale: 2, default: 0.0
      t.decimal :current_balance, precision: 10, scale: 2, default: 0.0
      t.decimal :minimum_payment, precision: 10, scale: 2, default: 0.0
      t.decimal :interest_charges, precision: 10, scale: 2, default: 0.0
      t.decimal :fees, precision: 10, scale: 2, default: 0.0
      t.decimal :payments_received, precision: 10, scale: 2, default: 0.0
      t.decimal :purchases_made, precision: 10, scale: 2, default: 0.0
      t.references :status, null: false, foreign_key: { to_table: :statuses, name: 'fk_credit_card_cycles_status' }
      t.datetime :statement_generated_at

      t.timestamps
    end

    add_index :credit_card_cycles, :uuid, unique: true
    add_index :credit_card_cycles, :cutting_date
    add_index :credit_card_cycles, :payment_due_date
    add_index :credit_card_cycles, [:credit_card_id, :cutting_date], unique: true
  end
end
