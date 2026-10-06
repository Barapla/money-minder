# frozen_string_literal: true

# FEAT-022: permite asociar un CreditCard a un producto del catalogo financiero
# (FinancialCatalogServices::Registry) mediante un identificador de texto.
class AddFinancialProductIdToCreditCards < ActiveRecord::Migration[7.2]
  def change
    add_column :credit_cards, :financial_product_id, :string
    add_index :credit_cards, :financial_product_id
  end
end
