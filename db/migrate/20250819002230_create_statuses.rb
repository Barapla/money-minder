# frozen_string_literal: true

# CreateStatuses Class
class CreateStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :statuses do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :code
      t.string :value
      t.string :color
      t.references :group_catalog, null: false,
                                   foreign_key: { to_table: :group_catalogs, name: 'fk_statuses_group_catalog' }

      t.timestamps
    end

    add_index :statuses, :uuid, unique: true
  end
end
