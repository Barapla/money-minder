# frozen_string_literal: true

# CreateCreditCards Class
class CreateCreditCards < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_cards do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.decimal :current_amount
      t.decimal :limit_amount
      t.decimal :debt_amount
      t.date :payday
      t.date :cutting_day
      t.references :budget, null: false, foreign_key: { to_table: :budgets, name: 'fk_credit_cards_budget' }

      t.timestamps
    end

    add_index :credit_cards, :uuid, unique: true
  end
end
