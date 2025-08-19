class CreditCardCycle < ApplicationRecord
  belongs_to :credit_card
  belongs_to :status
  # has_many :credit_card_histories, dependent: :destroy
  # has_many :transactions, through: :credit_card_histories

  validates :cutting_date, presence: true
  validates :payment_due_date, presence: true

  # Campos del modelo
  # :id => :integer,
  # :credit_card_id => :integer,
  # :cutting_date => :date,              # Fecha de corte de este ciclo
  # :payment_due_date => :date,          # Fecha de vencimiento de pago
  # :statement_balance => :decimal,      # Balance al momento del corte
  # :current_balance => :decimal,        # Balance actual (cambia con transacciones)
  # :minimum_payment => :decimal,        # Pago mínimo requerido
  # :interest_charges => :decimal,       # Intereses aplicados
  # :fees => :decimal,                   # Comisiones aplicadas
  # :payments_received => :decimal,      # Pagos recibidos en este ciclo
  # :purchases_made => :decimal,         # Compras realizadas en este ciclo
  # :status => :string,                  # 'open', 'closed'
  # :statement_generated_at => :datetime, # Cuándo se generó el estado
  # :created_at => :datetime,
  # :updated_at => :datetime

  scope :by_status, ->(code) { joins(:status).where(statuses: { code: } ) }
  scope :open, -> { by_status('open') }
  scope :closed, -> { by_status('closed') }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :due_soon, -> { where('payment_due_date <= ?', Date.current + 7.days) }

  # **MÉTODOS DEL CICLO**
  def process_transaction(transaction)
    case transaction.transaction_type.code
    when 'income'
      process_payment(transaction)
    when 'expense'
      process_purchase(transaction)
    end
  end

  def process_payment(transaction)
    amount = transaction.amount
    self.payments_received += amount
    self.current_balance = [current_balance - amount, 0].max
    save!
  end

  def process_purchase(transaction)
    amount = transaction.amount
    self.purchases_made += amount
    self.current_balance += amount
    save!
  end

  def is_current_cycle?
    Date.current.between?(cutting_date, next_cutting_date - 1.day)
  end

  def is_closed?
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
    self.statement_balance = current_balance
    self.status = Status.find_by(code: 'closed')
    self.statement_generated_at = Time.current
    calculate_minimum_payment
    save!
  end

  def utilization_at_closing
    return 0 if credit_card.limit_amount.zero?
    (statement_balance / credit_card.limit_amount * 100).round(2)
  end

  # Para reportes y análisis
  def net_activity
    purchases_made - payments_received
  end

  def payment_behavior
    return 'no_activity' if statement_balance.zero?
    return 'full_payment' if payments_received >= statement_balance
    return 'minimum_payment' if payments_received >= minimum_payment
    return 'partial_payment' if payments_received > 0
    'no_payment'
  end

  private

  def calculate_minimum_payment
    base_percentage = 0.05
    self.minimum_payment = (statement_balance * base_percentage).round(2)

    if credit_card.interest_rate.present?
      interest = statement_balance * (credit_card.interest_rate / 100)
      self.minimum_payment += interest
    end

    self.minimum_payment = [minimum_payment, 25.0].max if statement_balance > 0
  end
end
