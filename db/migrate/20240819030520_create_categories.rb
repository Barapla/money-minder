# frozen_string_literal: true

# CreateCategories Class
class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :name
      t.text :description
      t.references :parent_category, foreign_key: { to_table: :categories }, null: true

      t.timestamps
    end

    add_index :categories, :uuid, unique: true
  end
end
