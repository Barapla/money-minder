# frozen_string_literal: true

# This migration added a name column to the budgets table.
class AddNameToBudgets < ActiveRecord::Migration[7.0]
  def up
    add_column :budgets, :name, :string, null: false
  end

  def down
    remove_column :budgets, :name
  end
end
