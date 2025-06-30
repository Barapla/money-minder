# frozen_string_literal: true

# CreateCatalogs Class
class CreateCatalogs < ActiveRecord::Migration[7.0]
  def change
    create_table :catalogs do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :value
      t.string :code
      t.references :group_catalog, null: false,
                                   foreign_key: { to_table: :group_catalogs, name: 'fk_catalogs_group_catalog' }

      t.timestamps
    end

    add_index :catalogs, :uuid, unique: true
  end
end
