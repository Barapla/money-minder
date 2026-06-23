# frozen_string_literal: true

class FixObligatoryPaymentsCategoryFk < ActiveRecord::Migration[7.2]
  def up
    remove_foreign_key :obligatory_payments, name: 'fk_obligatory_payments_category'
    add_foreign_key :obligatory_payments, :categories, column: :category_id,
                                                       name: 'fk_obligatory_payments_category'
  end

  def down
    remove_foreign_key :obligatory_payments, name: 'fk_obligatory_payments_category'
    add_foreign_key :obligatory_payments, :catalogs, column: :category_id,
                                                     name: 'fk_obligatory_payments_category'
  end
end
