# frozen_string_literal: true

class CreateFinancialProductBenefits < ActiveRecord::Migration[7.2]
  def change
    create_table :financial_product_benefits do |t|
      t.references :financial_product, null: false, foreign_key: true
      t.integer :benefit_type, null: false
      t.decimal :base_value, precision: 10, scale: 2, null: false
      t.decimal :reduced_value, precision: 10, scale: 2
      t.decimal :amount_cap, precision: 10, scale: 2
      t.integer :unit, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :financial_product_benefits, %i[financial_product_id active]
  end
end
