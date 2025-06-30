# frozen_string_literal: true

# CreateBudgets Class
class CreateBudgets < ActiveRecord::Migration[7.0]
  def change
    create_table :budgets do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.decimal :current_amount
      t.decimal :limit_amount
      t.references :budget_type, null: false,
                                 foreign_key: { to_table: :catalogs, name: 'fk_budgets_budget_type' }
      t.references :color, null: false, foreign_key: { to_table: :catalogs, name: 'fk_budgets_color' }
      t.references :icon, null: false, foreign_key: { to_table: :catalogs, name: 'fk_budgets_icon' }

      t.timestamps
    end

    add_index :budgets, :uuid, unique: true
  end
end
