# frozen_string_literal: true

# CreateRoles Class
class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :name

      t.timestamps
    end

    add_index :roles, :uuid, unique: true
  end
end