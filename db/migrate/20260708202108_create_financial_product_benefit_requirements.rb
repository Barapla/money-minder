# frozen_string_literal: true

class CreateFinancialProductBenefitRequirements < ActiveRecord::Migration[7.2]
  def change
    create_table :financial_product_benefit_requirements do |t|
      t.references :financial_product_benefit, null: false, foreign_key: true,
                                               index: { name: 'index_fpbr_on_benefit_id' }
      t.integer :requirement_type, null: false, default: 0
      t.integer :min_transactions_count
      t.decimal :min_amount_per_transaction, precision: 10, scale: 2
      t.decimal :min_accumulated_amount, precision: 10, scale: 2
      t.decimal :monthly_fee_amount, precision: 10, scale: 2
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :financial_product_benefit_requirements, :requirement_type
    add_index :financial_product_benefit_requirements, :active
  end
end
