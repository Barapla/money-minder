# frozen_string_literal: true

class CreateFinancialProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :financial_products do |t|
      t.references :financial_institution, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :product_type, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :financial_products, 'LOWER(name), financial_institution_id',
              unique: true,
              name: 'index_financial_products_on_lower_name_and_institution'
    add_index :financial_products, :product_type
    add_index :financial_products, :active
  end
end
