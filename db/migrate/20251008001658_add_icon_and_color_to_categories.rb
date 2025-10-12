class AddIconAndColorToCategories < ActiveRecord::Migration[7.0]
  def up
    add_reference :categories, :icon, null: :true, foreign_key: { to_table: :catalogs, name: 'fk_categories_icon' }
    add_reference :categories, :color, null: :true, foreign_key: { to_table: :catalogs, name: 'fk_categories_color' }
  end

  def down
    remove_reference :categories, :icon, foreign_key: { to_table: :catalogs, name: 'fk_categories_icon' }
    remove_reference :categories, :color, foreign_key: { to_table: :catalogs, name: 'fk_categories_color' }
  end
end
