# frozen_string_literal: true

# FEAT-020: el catalogo de instituciones/productos/beneficios financieros pasa de BD
# a clases Ruby en FinancialCatalogServices. Ver CLAUDE.md seccion "Financial Products Catalog".
class RemoveFinancialCatalogTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :financial_product_benefit_requirements if table_exists?(:financial_product_benefit_requirements)
    drop_table :financial_product_benefits if table_exists?(:financial_product_benefits)
    drop_table :financial_products if table_exists?(:financial_products)
    # force: :cascade tambien elimina el FK huerfano credit_card_products.financial_institution_id,
    # columna sin controller/vista/ruta asociada (scaffolding sin usar).
    drop_table :financial_institutions, force: :cascade if table_exists?(:financial_institutions)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
