# frozen_string_literal: true

# Cuanto de una transaccion abona a una deuda.
#
# Existe porque el monto aplicado NO es el de la transaccion:
#   - Un cobro de $1,250 del que solo $250 son de esta deuda.
#   - Un cobro de $215 que valio $250, porque se netearon $35 que se debian.
#
# Deliberadamente no se valida contra el monto de la transaccion: abonar de mas
# es un caso real, no un error.
class DebtAllocation < ApplicationRecord
  belongs_to :debt
  belongs_to :transaction_record, class_name: 'Transaction', foreign_key: 'transaction_id',
                                  inverse_of: :debt_allocations

  validates :amount, numericality: { greater_than: 0 }
  validates :debt_id, uniqueness: { scope: :transaction_id }

  delegate :transaction_date, :description, to: :transaction_record, allow_nil: true

  # Lo que sobro de la transaccion sin asignar a esta deuda. Negativo cuando el
  # abono vale mas que el movimiento.
  def unallocated_amount
    transaction_record.amount.to_f - amount.to_f
  end

  def partial?
    unallocated_amount.positive?
  end

  def symbolic?
    unallocated_amount.negative?
  end
end
