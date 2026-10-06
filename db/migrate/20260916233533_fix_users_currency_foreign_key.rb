# frozen_string_literal: true

# La migracion original de Devise apuntaba users.currency_id a la tabla roles, lo
# que impedia guardar una moneda real al usuario. Se limpian los valores que no
# corresponden a una moneda y se apunta la llave foranea a currencies.
class FixUsersCurrencyForeignKey < ActiveRecord::Migration[7.2]
  def up
    remove_foreign_key :users, name: 'fk_users_currency'
    execute <<~SQL.squish
      UPDATE users SET currency_id = NULL
      WHERE currency_id IS NOT NULL
        AND currency_id NOT IN (SELECT id FROM currencies)
    SQL
    add_foreign_key :users, :currencies, column: :currency_id, name: 'fk_users_currency'
  end

  def down
    remove_foreign_key :users, name: 'fk_users_currency'
    add_foreign_key :users, :roles, column: :currency_id, name: 'fk_users_currency'
  end
end
