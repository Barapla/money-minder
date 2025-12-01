class AddDoneToObligatoryPayment < ActiveRecord::Migration[7.0]
  def up
    add_column :obligatory_payments, :done, :boolean, default: false
  end

  def down
    remove_column :obligatory_payments, :done
  end
end
