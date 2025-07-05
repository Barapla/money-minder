# frozen_string_literal: true

# Migration to add a personal boolean to budgets
class AddPersonalBooleanToBudgets < ActiveRecord::Migration[7.0]
  def up
    add_column :budgets, :personal, :boolean, default: false
  end

  def down
    remove_column :budgets, :personal
  end
end
