# frozen_string_literal: true

# CreditCardCycle model
class CreditCardCycle < ApplicationRecord
  MINIMUM_PAYMENT_RATE = 0.05
  MINIMUM_PAYMENT_FLOOR = 25.0

  belongs_to :credit_card
  belongs_to :status
  has_many :credit_card_cycle_transactions, dependent: :destroy
  has_many :transactions, through: :credit_card_histories

  validates :cutting_date, presence: true
  validates :payment_due_date, presence: true

  scope :by_status, ->(code) { joins(:status).where(statuses: { code: }) }
  scope :open, -> { by_status('open') }
  scope :closed, -> { by_status('closed') }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :due_soon, -> { where('payment_due_date <= ?', Date.current + 7.days) }

  after_save :handle_balance_updates

  def push_credit_card_closing_balance
    next_cycle&.update(historical_balance: closing_balance)
  end

  def update_budget_amount
    credit_card.update_budget_amount
  end

  def update_credit_card_closing_balance
    update(closing_balance: cycle_balance + historical_balance)
  end

  # **MÉTODOS DEL CICLO**
  def process_transaction(transaction)
    case transaction.transaction_type.code
    when 'income'
      process_payment(transaction)
    when 'expense'
      process_purchase(transaction)
    end

    credit_card_cycle_transactions.create!(transaction_record: transaction)
  end

  def process_payment(transaction)
    amount = transaction.amount
    self.payments += amount
    self.cycle_balance -= amount
    save!
  end

  def process_purchase(transaction)
    amount = transaction.amount
    self.purchases += amount
    self.cycle_balance += amount
    save!
  end

  def current_cycle?
    Date.current.between?(cutting_date, next_cutting_date - 1.day)
  end

  def closed?
    status.code == 'closed'
  end

  def days_until_due
    return 0 if payment_due_date < Date.current

    (payment_due_date - Date.current).to_i
  end

  def next_cutting_date
    next_month = cutting_date + 1.month
    Date.new(next_month.year, next_month.month, cutting_date.day)
  rescue ArgumentError
    # Manejar casos como 31 de febrero
    cutting_date + 1.month
  end

  def close_cycle!
    self.status = Status.find_by(code: 'closed')
    self.statement_generated_at = Time.current
    calculate_minimum_payment
    save!
  end

  # Deuda que quedo al momento del corte: lo arrastrado mas las compras del periodo,
  # menos los pagos hechos antes de cortar (esos aligeran el corte, no lo liquidan).
  # Para un ciclo que aun no corta equivale al saldo corriente.
  def statement_balance
    historical_balance.to_f + purchases.to_f - payments_before_cut
  end

  def payments_before_cut
    sum_cycle_payments { |date| date <= cutting_date }
  end

  # Pagos aplicados al estado de cuenta ya cortado.
  def payments_after_cut
    sum_cycle_payments { |date| date > cutting_date }
  end

  def fully_paid?
    payments_after_cut >= statement_balance
  end

  # El minimo solo se persiste al cerrar el ciclo, asi que se estima con la misma
  # tasa sobre la deuda cortada.
  def estimated_minimum_payment
    return minimum_payment if minimum_payment.to_f.positive?
    return 0.0 if statement_balance <= 0

    [(statement_balance * MINIMUM_PAYMENT_RATE).round(2), MINIMUM_PAYMENT_FLOOR].max
  end

  # Etapa del ciclo segun el calendario: corriendo hasta el corte, por pagar
  # durante la ventana de pago, y despues cerrado o vencido segun se haya pagado.
  def lifecycle_status_code
    today = Date.current
    return 'open' if today <= cutting_date
    return 'pending_payment' if today <= payment_due_date

    fully_paid? ? 'closed' : 'overdue'
  end

  # Porcentaje del limite que la tarjeta traia el dia del corte: el saldo cortado
  # antes de los pagos de la ventana. Es el numero que se reporta al buro, y no
  # baja aunque pagues despues (para eso hay que pagar ANTES del corte).
  def utilization_at_cut
    limit = credit_card.limit_amount.to_f
    return 0.0 if limit <= 0

    (statement_balance / limit * 100).round(1)
  end

  # Para reportes y análisis
  def net_activity
    purchases - payments
  end

  # Que tanto se cubrio del estado de cuenta cortado, comparando solo los pagos
  # hechos dentro de la ventana de pago contra la deuda del corte.
  def payment_behavior
    return 'no_activity' if purchases.to_f.zero? && payments.to_f.zero?

    paid = payments_after_cut
    return 'full_payment' if paid >= statement_balance
    return 'no_payment' unless paid.positive?
    return 'minimum_payment' if paid >= estimated_minimum_payment

    'below_minimum'
  end

  def next_cycle
    credit_card.credit_card_cycles.where('cutting_date > ?', cutting_date).order(cutting_date: :asc).first
  end

  def previous_cycle
    credit_card.credit_card_cycles.where('cutting_date < ?', cutting_date).order(cutting_date: :desc).first
  end

  private

  def sum_cycle_payments
    credit_card_cycle_transactions.filter_map do |link|
      record = link.transaction_record
      next unless record && record.transaction_type.code == 'income'
      next unless yield(record.transaction_date.to_date)

      record.amount.to_f
    end.sum
  end

  def handle_balance_updates
    if balance_changed_or_new_record?
      update_credit_card_closing_balance
      push_credit_card_closing_balance if should_push_balance?
      update_budget_amount if should_push_balance?
    elsif should_push_balance?
      push_credit_card_closing_balance
      update_budget_amount
    end
  end

  def balance_changed_or_new_record?
    new_record? || saved_change_to_cycle_balance? || saved_change_to_historical_balance?
  end

  def should_push_balance?
    new_record? || saved_change_to_closing_balance?
  end

  def calculate_minimum_payment
    self.minimum_payment = (closing_balance * MINIMUM_PAYMENT_RATE).round(2)
    self.minimum_payment = [minimum_payment, MINIMUM_PAYMENT_FLOOR].max if closing_balance.positive?
  end
end
