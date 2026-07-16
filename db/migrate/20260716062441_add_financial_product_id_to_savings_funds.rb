# frozen_string_literal: true

# FEAT-022: permite asociar un SavingsFund a un producto del catalogo financiero
# (FinancialCatalogServices::Registry) mediante un identificador de texto.
class AddFinancialProductIdToSavingsFunds < ActiveRecord::Migration[7.2]
  def change
    add_column :savings_funds, :financial_product_id, :string
    add_index :savings_funds, :financial_product_id
  end
end
