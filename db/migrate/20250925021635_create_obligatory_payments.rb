# frozen_string_literal: true

# CreateObligatoryPayments Class
class CreateObligatoryPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :obligatory_payments do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :user, null: false, foreign_key: { to_table: :users, name: 'fk_obligatory_payments_user' }
      t.string :name
      t.decimal :amount
      t.references :category, null: false, foreign_key: { to_table: :catalogs, name: 'fk_obligatory_payments_category' }
      t.text :description
      t.references :color, null: false, foreign_key: { to_table: :catalogs, name: 'fk_obligatory_payments_color' }
      t.references :icon, null: false, foreign_key: { to_table: :catalogs, name: 'fk_obligatory_payments_icon' }

      t.timestamps
    end

    add_index :obligatory_payments, :uuid, unique: true
  end
end
