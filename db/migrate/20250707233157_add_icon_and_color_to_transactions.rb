# frozen_string_literal: true

# This migration adds references to the `icon` and `color` columns in the `transactions` table,
class AddIconAndColorToTransactions < ActiveRecord::Migration[7.0]
  def up
    add_reference :transactions, :icon, foreign_key: { to_table: :catalogs, name: 'fk_transactions_icon' }
    add_reference :transactions, :color, foreign_key: { to_table: :catalogs, name: 'fk_transactions_color' }
  end

  def down
    remove_reference :transactions, :icon, foreign_key: { to_table: :catalogs, name: 'fk_transactions_icon' }
    remove_reference :transactions, :color, foreign_key: { to_table: :catalogs, name: 'fk_transactions_color' }
  end
end
