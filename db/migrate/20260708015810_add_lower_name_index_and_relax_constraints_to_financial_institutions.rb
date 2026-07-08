# frozen_string_literal: true

# Agrega indice unico case-insensitive en name y relaja restricciones de columnas
# heredadas del schema original para soportar el CRUD admin de FEAT-016.
class AddLowerNameIndexAndRelaxConstraintsToFinancialInstitutions < ActiveRecord::Migration[7.2]
  def up
    add_index :financial_institutions, 'LOWER(name)', unique: true,
                                                      name: 'index_financial_institutions_on_lower_name'

    change_column_null :financial_institutions, :code, true
    change_column_null :financial_institutions, :color_id, true
  end

  def down
    remove_index :financial_institutions, name: 'index_financial_institutions_on_lower_name'

    change_column_null :financial_institutions, :code, false
    change_column_null :financial_institutions, :color_id, false
  end
end
