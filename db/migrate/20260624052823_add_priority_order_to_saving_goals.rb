# frozen_string_literal: true

# Agrega priority_order a saving_goals para ordenamiento de metas de ahorro.
# El backfill asigna valores secuenciales por usuario en orden de creación.
class AddPriorityOrderToSavingGoals < ActiveRecord::Migration[7.2]
  def up
    add_column :saving_goals, :priority_order, :integer

    User.find_each do |user|
      user.saving_goals.order(created_at: :asc).each_with_index do |goal, index|
        goal.update_column(:priority_order, index + 1)
      end
    end

    change_column_null :saving_goals, :priority_order, false
    add_index :saving_goals, %i[user_id priority_order], unique: true
  end

  def down
    remove_index :saving_goals, column: %i[user_id priority_order]
    remove_column :saving_goals, :priority_order
  end
end
