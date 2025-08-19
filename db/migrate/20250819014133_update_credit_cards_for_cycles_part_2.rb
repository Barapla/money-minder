class UpdateCreditCardsForCyclesPart2 < ActiveRecord::Migration[7.0]
  def up
    # Cambiar payday por payment_due_days para mayor flexibilidad
    remove_column :credit_cards, :payday
    remove_column :credit_cards, :cutting_day
    remove_column :credit_cards, :debt_amount
    remove_column :credit_cards, :current_amount
  end

  def down
    # Revertir cambios si es necesario
    add_column :credit_cards, :payday, :date
    add_column :credit_cards, :cutting_day, :date
    add_column :credit_cards, :debt_amount, :decimal, precision: 10, scale: 2
    add_column :credit_cards, :current_amount, :decimal, precision: 10, scale: 2
  end
end
