# frozen_string_literal: true

# AddBudgetIdToTransactions Migration
class AddBudgetIdToTransactions < ActiveRecord::Migration[7.0]
  def up
    add_reference :transactions, :budget, null: true,
                                          foreign_key: { to_table: :budgets, name: 'fk_transactions_budget' }
  end

  def down
    remove_reference :transactions, :budget, foreign_key: { to_table: :budgets, name: 'fk_transactions_budget' }
  end
end
