class UpdateCreditCardsForCyclesPart1 < ActiveRecord::Migration[7.0]
  def up
    add_column :credit_cards, :cutting_day_int, :integer
    add_column :credit_cards, :payment_due_days, :integer, default: 5
  end

  def down
    remove_column :credit_cards, :cutting_day_int
    remove_column :credit_cards, :payment_due_days
  end
end
