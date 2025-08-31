class AddHistoricalDebtAndCurrentDebtToCreditCardCycles < ActiveRecord::Migration[7.0]
  def up
    add_column :credit_card_cycles, :historical_balance, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :credit_card_cycles, :cycle_balance, :decimal, precision: 15, scale: 2, default: 0.0, null: false

    remove_column :credit_card_cycles, :statement_balance
  end

  def down
    remove_column :credit_card_cycles, :historical_debt
    remove_column :credit_card_cycles, :cycle_balance

    add_column :credit_card_cycles, :statement_balance, :decimal, precision: 15, scale: 2, default: 0.0, null: false
  end
end
