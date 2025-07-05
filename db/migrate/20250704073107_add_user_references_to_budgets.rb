# frozen_string_literal: true

# Migration to add user references to budgets
class AddUserReferencesToBudgets < ActiveRecord::Migration[7.0]
  def up
    add_reference :budgets, :user, null: false, foreign_key: { to_table: :users, name: 'fk_budgets_user' }
  end

  def down
    remove_reference :budgets, :user, foreign_key: { to_table: :users, name: 'fk_budgets_user' }
  end
end
