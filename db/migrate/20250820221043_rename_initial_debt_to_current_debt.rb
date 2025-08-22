class RenameInitialDebtToCurrentDebt < ActiveRecord::Migration[7.0]
  def up
    rename_column :credit_cards, :initial_debt, :current_debt
  end

  def down
    rename_column :credit_cards, :current_debt, :initial_debt
  end
end
