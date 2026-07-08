# frozen_string_literal: true

class AddRequirementsLogicToFinancialProductBenefits < ActiveRecord::Migration[7.2]
  def change
    add_column :financial_product_benefits, :requirements_logic, :integer, null: false, default: 0
    add_index :financial_product_benefits, :requirements_logic
  end
end
