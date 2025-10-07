class AddCodeToCategories < ActiveRecord::Migration[7.0]
  def up
    add_column :categories, :code, :string
    add_index :categories, :code, unique: true
  end

  def down
    remove_index :categories, :code
    remove_column :categories, :code
  end
end
