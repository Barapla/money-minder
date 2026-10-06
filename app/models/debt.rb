# frozen_string_literal: true

# Una deuda propia o ajena. `direction` separa lo que me deben (receivable) de lo
# que debo (payable).
#
# El saldo NO se guarda: se calcula sumando las transacciones ligadas. Asi un
# abono extra para liquidar antes, o un pago de menos, cuadran solos sin tener
# que reescribir un contador — que era justo el problema de llevarlo a mano.
class Debt < ApplicationRecord
  belongs_to :user
  belongs_to :budget, optional: true
  belongs_to :currency, optional: true
  belongs_to :category, optional: true
  belongs_to :color, class_name: 'Catalog', optional: true
  belongs_to :icon, class_name: 'Catalog', optional: true
  # La deuda es la dueña del recordatorio que genera: al borrarla se lo lleva.
  belongs_to :obligatory_payment, optional: true, dependent: :destroy

  has_many :debt_allocations, dependent: :destroy
  has_many :transactions, through: :debt_allocations, source: :transaction_record

  enum :direction, { receivable: 0, payable: 1 }
  enum :status, { active: 0, settled: 1, cancelled: 2 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :principal_amount, numericality: { greater_than: 0 }
  validates :installment_amount, numericality: { greater_than: 0 }, allow_nil: true
  # La fecha de inicio solo es obligatoria con plan de pagos: de ahi arranca la
  # recurrencia del recordatorio. Una deuda suelta ("fulano me debe 500") no
  # necesita fecha ni cuotas.
  validates :started_on, presence: true, if: :installments?
  validates :expected_end_on,
            comparison: { greater_than_or_equal_to: :started_on },
            allow_nil: true,
            if: -> { started_on.present? }

  # NULLS LAST para que las deudas sin fecha no se monten arriba de las recientes.
  scope :recent_first, -> { order(Arel.sql('started_on DESC NULLS LAST, created_at DESC')) }
  scope :outstanding, -> { where(status: :active) }

  # ── Saldo ────────────────────────────────────────────────────────────────

  # Suma de lo APLICADO, no del monto de las transacciones: una misma puede
  # abonar de menos (parte era de otra cosa) o de mas (se neteo algo).
  def paid_amount
    debt_allocations.sum(:amount).to_f
  end

  def remaining_amount
    [principal_amount.to_f - paid_amount, 0].max
  end

  def progress_percentage
    return 0.0 unless principal_amount.to_f.positive?

    ((paid_amount / principal_amount.to_f) * 100).clamp(0, 100).round(1)
  end

  def overpaid_amount
    [paid_amount - principal_amount.to_f, 0].max
  end

  def fully_paid?
    remaining_amount.zero?
  end

  # ── Plan de pagos ────────────────────────────────────────────────────────

  def installments?
    installment_amount.to_f.positive?
  end

  # Cuantos pagos del tamaño acordado faltan. Con abonos extra baja mas rapido
  # que el calendario original, que es justo lo que se queria poder ver.
  def remaining_installments
    return nil unless installments?

    (remaining_amount / installment_amount.to_f).ceil
  end

  def next_due_date
    obligatory_payment&.next_due_date
  end

  # El tipo de recordatorio que le toca: lo que me deben entra como ingreso.
  def reminder_type
    receivable? ? :income : :payment
  end

  def transaction_type_code
    receivable? ? 'income' : 'expense'
  end

  def settle!
    update!(status: :settled)
  end

  # Movimientos que podrian abonar a esta deuda: del tipo que le toca por su
  # direccion y que todavia no estan ligados a ella. Se permite ligar uno que ya
  # abona a OTRA deuda, porque un mismo deposito puede traer varias.
  def candidate_transactions(limit: 40)
    user.transactions
        .joins(:transaction_type)
        .where(catalogs: { code: transaction_type_code })
        .where.not(id: debt_allocations.select(:transaction_id))
        .order(transaction_date: :desc)
        .limit(limit)
  end
end
