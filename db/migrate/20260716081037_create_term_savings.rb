# frozen_string_literal: true

# FEAT-024: ahorro a plazo fijo (ej. Ahorro Congelado Nu 7/28/90/180 dias). El capital
# queda bloqueado hasta matures_at y no cuenta como disponible para metas de ahorro
# mientras status sea :active y matures_at sea futuro (ver SavingGoalServices::ProgressCalculator).
class CreateTermSavings < ActiveRecord::Migration[7.2]
  def change
    create_table :term_savings do |t|
      t.references :budget, null: false, foreign_key: { to_table: :budgets, name: 'fk_term_savings_budget' }
      t.integer :term_days, null: false
      t.decimal :rate_locked, precision: 5, scale: 4, null: false
      t.date :started_at, null: false
      t.date :matures_at, null: false
      t.decimal :principal_amount, precision: 15, scale: 2, null: false
      t.string :financial_product_id
      t.integer :status, default: 0, null: false
      t.string :name

      t.timestamps
    end

    add_index :term_savings, :financial_product_id
    add_index :term_savings, :status
  end
end
