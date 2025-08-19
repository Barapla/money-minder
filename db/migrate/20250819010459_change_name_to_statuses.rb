class ChangeNameToStatuses < ActiveRecord::Migration[7.0]
  def up
    rename_column :statuses, :value, :name
  end

  def down
    rename_column :statuses, :name, :value
  end
end
