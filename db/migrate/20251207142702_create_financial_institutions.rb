# frozen_string_literal: true

# CreateFinancialInstitutions Class
class CreateFinancialInstitutions < ActiveRecord::Migration[7.0]
  def change
    create_table :financial_institutions do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :name, null: false
      t.string :code, null: false
      t.string :country, null: false, default: 'MX'
      t.string :logo_url
      t.references :color, null: false, foreign_key: { to_table: :catalogs, name: 'fk_financial_institutions_color' }
  
      t.timestamps
    end

    add_index :financial_institutions, :uuid, unique: true
    add_index :financial_institutions, :code, unique: true
  end
end