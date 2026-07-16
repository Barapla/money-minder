# frozen_string_literal: true

# FEAT-022: permite asociar un Budget a un producto del catalogo financiero
# (FinancialCatalogServices::Registry) mediante un identificador de texto.
class AddFinancialProductIdToBudgets < ActiveRecord::Migration[7.2]
  def change
    add_column :budgets, :financial_product_id, :string
    add_index :budgets, :financial_product_id
  end
end
