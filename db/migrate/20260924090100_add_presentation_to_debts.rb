# frozen_string_literal: true

# ObligatoryPayment exige category, color e icon (belongs_to no opcionales), asi
# que la deuda que lo genera tiene que traerlos. De paso le dan cara propia al
# listado de deudas, igual que en recordatorios y transacciones.
class AddPresentationToDebts < ActiveRecord::Migration[7.2]
  def change
    add_reference :debts, :category, foreign_key: true
    add_reference :debts, :color, foreign_key: { to_table: :catalogs }
    add_reference :debts, :icon, foreign_key: { to_table: :catalogs }
  end
end
