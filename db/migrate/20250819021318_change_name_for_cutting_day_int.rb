class ChangeNameForCuttingDayInt < ActiveRecord::Migration[7.0]
  def up
    rename_column :credit_cards, :cutting_day_int, :cutting_day
  end

  def down
    rename_column :credit_cards, :cutting_day, :cutting_day_int
  end
end
