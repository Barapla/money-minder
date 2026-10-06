# frozen_string_literal: true

# Crea la tabla saving_goals para metas de ahorro de usuario con progreso calculado on-demand.
class CreateSavingGoals < ActiveRecord::Migration[7.2]
  def change
    create_table :saving_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :target_amount, precision: 15, scale: 2, null: false
      t.date :deadline
      t.integer :status, default: 0, null: false
      t.timestamps
    end

    add_index :saving_goals, %i[user_id status]
  end
end
