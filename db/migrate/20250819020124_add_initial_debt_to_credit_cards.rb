class AddInitialDebtToCreditCards < ActiveRecord::Migration[7.0]
  def up
    add_column :credit_cards, :initial_debt, :decimal, precision: 10, scale: 2, default: 0.0
  end

  def down
    remove_column :credit_cards, :initial_debt
  end
end
