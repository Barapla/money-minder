# frozen_string_literal: true

# CreateGroupCatalogs Class
class CreateGroupCatalogs < ActiveRecord::Migration[7.0]
  def change
    create_table :group_catalogs do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :name
      t.string :code

      t.timestamps
    end

    add_index :group_catalogs, :uuid, unique: true
  end
end
