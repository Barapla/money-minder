# frozen_string_literal: true

# Deudas propias y ajenas. `direction` separa lo que me deben (receivable) de lo
# que debo (payable); el saldo no se guarda, se calcula sumando las transacciones
# ligadas, para que un abono extra o un pago de menos cuadren solos.
#
# obligatory_payment_id apunta al recordatorio que la deuda genera cuando tiene
# plan de pagos. Es la deuda la dueña: al borrarla se lleva su recordatorio.
class CreateDebts < ActiveRecord::Migration[7.2]
  def change
    create_table :debts do |t|
      t.string :uuid, default: -> { 'gen_random_uuid()' }, null: false
      t.boolean :active, default: true, null: false
      t.references :user, null: false, foreign_key: true
      t.references :obligatory_payment, foreign_key: true
      t.references :budget, foreign_key: true
      t.references :currency, foreign_key: true

      t.integer :direction, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :name, null: false
      t.string :counterparty
      t.decimal :principal_amount, precision: 12, scale: 2, null: false
      t.decimal :installment_amount, precision: 12, scale: 2
      t.date :started_on, null: false
      t.date :expected_end_on
      t.text :notes

      t.timestamps
    end

    add_index :debts, :uuid, unique: true
    add_index :debts, %i[user_id direction status]

    add_reference :transactions, :debt, foreign_key: true, index: true
  end
end
