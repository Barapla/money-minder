class UpdateCreditCardCycles < ActiveRecord::Migration[7.0]
  def up
    add_column :credit_card_cycles, :period_start_date, :date
    add_column :credit_card_cycles, :opening_balance, :decimal, precision: 10, scale: 2
    
    # Renombrar para claridad
    rename_column :credit_card_cycles, :purchases_made, :purchases
    rename_column :credit_card_cycles, :payments_received, :payments
    rename_column :credit_card_cycles, :interest_charges, :interest
    rename_column :credit_card_cycles, :current_balance, :closing_balance
    
    # Cambiar status_id a enum directo
    add_column :credit_card_cycles, :status, :integer, default: 0
    # 0: open, 1: closed, 2: paid

  end

  def down
    remove_column :credit_card_cycles, :period_start_date
    remove_column :credit_card_cycles, :opening_balance

    rename_column :credit_card_cycles, :purchases, :purchases_made
    rename_column :credit_card_cycles, :payments, :payments_received
    rename_column :credit_card_cycles, :interest, :interest_charges
    rename_column :credit_card_cycles, :closing_balance, :current_balance

    remove_column :credit_card_cycles, :status
  end
end
