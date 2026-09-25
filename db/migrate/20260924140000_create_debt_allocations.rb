# frozen_string_literal: true

# Lo que una transaccion abona a una deuda, que NO siempre es su monto:
#
#   - Un cobro de $1,250 donde solo $250 son de esta deuda (abona de menos).
#   - Un cobro de $215 que en realidad valio $250 porque se netearon $35 que se
#     debian al otro (abona de mas).
#
# Por eso el monto aplicado vive aqui y no en la transaccion, y una misma
# transaccion puede repartirse entre varias deudas.
class CreateDebtAllocations < ActiveRecord::Migration[7.2]
  def change
    create_table :debt_allocations do |t|
      t.string :uuid, default: -> { 'gen_random_uuid()' }, null: false
      t.references :debt, null: false, foreign_key: true
      t.references :transaction, null: false, foreign_key: { to_table: :transactions }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    add_index :debt_allocations, :uuid, unique: true
    add_index :debt_allocations, %i[debt_id transaction_id], unique: true

    remove_reference :transactions, :debt, foreign_key: true
  end
end
