# frozen_string_literal: true

# This migration adds debt_amount, payday, and cutting_day columns to the budgets table.
class AddDebtAmountPaydayAndCuttingDayToBudgets < ActiveRecord::Migration[7.0]
  def up
    add_column :budgets, :debt_amount, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :budgets, :payday, :date
    add_column :budgets, :cutting_day, :date
  end

  def down
    remove_column :budgets, :debt_amount
    remove_column :budgets, :payday
    remove_column :budgets, :cutting_day
  end
end
