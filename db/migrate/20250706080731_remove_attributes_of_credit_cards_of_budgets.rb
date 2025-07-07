# frozen_string_literal: true

# RemoveAttributesOfCreditCardsOfBudgets Class
class RemoveAttributesOfCreditCardsOfBudgets < ActiveRecord::Migration[7.0]
  def up
    remove_column :budgets, :limit_amount, :decimal, precision: 10, scale: 2
    remove_column :budgets, :debt_amount, :decimal, precision: 10, scale: 2
    remove_column :budgets, :payday, :date
    remove_column :budgets, :cutting_day, :date
  end

  def down
    add_column :budgets, :limit_amount, :decimal, precision: 10, scale: 2, default: '0.0'
    add_column :budgets, :debt_amount, :decimal, precision: 10, scale: 2, default: '0.0'
    add_column :budgets, :payday, :date
    add_column :budgets, :cutting_day, :date
  end
end
