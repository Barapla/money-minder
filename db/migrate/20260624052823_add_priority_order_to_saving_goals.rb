# frozen_string_literal: true

# Agrega priority_order a saving_goals para ordenamiento de metas de ahorro.
# El backfill asigna valores secuenciales por usuario en orden de creación.
class AddPriorityOrderToSavingGoals < ActiveRecord::Migration[7.2]
  BACKFILL_SQL = <<~SQL
    UPDATE saving_goals sg
    SET priority_order = sub.row_num
    FROM (
      SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC) AS row_num
      FROM saving_goals
    ) sub
    WHERE sg.id = sub.id
  SQL

  def up
    add_column :saving_goals, :priority_order, :integer
    execute BACKFILL_SQL
    change_column_null :saving_goals, :priority_order, false
    add_index :saving_goals, %i[user_id priority_order], unique: true
  end

  def down
    remove_index :saving_goals, column: %i[user_id priority_order]
    remove_column :saving_goals, :priority_order
  end
end
