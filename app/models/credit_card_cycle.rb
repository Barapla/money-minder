class CreditCardCycle < ApplicationRecord
  belongs_to :credit_card
  belongs_to :status
  # has_many :credit_card_histories, dependent: :destroy
  # has_many :transactions, through: :credit_card_histories

  validates :cutting_date, presence: true
  validates :payment_due_date, presence: true

  scope :by_status, ->(code) { joins(:status).where(statuses: { code: } ) }
  scope :open, -> { by_status('open') }
  scope :closed, -> { by_status('closed') }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :due_soon, -> { where('payment_due_date <= ?', Date.current + 7.days) }

  after_save :handle_balance_updates

  def push_credit_card_current_balance
    next_cycle&.update(historical_balance: current_balance)
  end

  def update_budget_amount
    credit_card.update_budget_amount
  end

  def update_credit_card_current_balance
    self.update(current_balance: cycle_balance + historical_balance)
  end

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
    self.cycle_balance -= amount
    save!
  end

  def process_purchase(transaction)
    puts "Processing purchase of amount: #{transaction.amount} on #{transaction.transaction_date}"
    amount = transaction.amount
    self.purchases_made += amount
    self.cycle_balance += amount
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
    self.status = Status.find_by(code: 'closed')
    self.statement_generated_at = Time.current
    calculate_minimum_payment
    save!
  end

  def utilization_at_closing
    return 0 if credit_card.limit_amount.zero?
    (current_balance / credit_card.limit_amount * 100).round(2)
  end

  # Para reportes y análisis
  def net_activity
    purchases_made - payments_received
  end

  def payment_behavior
    return 'no_activity' if cycle_balance.zero?
    return 'full_payment' if payments_received >= current_balance
    return 'minimum_payment' if payments_received >= minimum_payment
    return 'partial_payment' if payments_received > 0
    'no_payment'
  end

  def next_cycle
    credit_card.credit_card_cycles.where('cutting_date > ?', cutting_date).order(cutting_date: :asc).first
  end

  def previous_cycle
    credit_card.credit_card_cycles.where('cutting_date < ?', cutting_date).order(cutting_date: :desc).first
  end

  private

  def handle_balance_updates
    puts "Handling balance updates for CreditCardCycle ID: #{id}"
    puts "Changed attributes: #{changes.keys}" if changes.any?
    puts "Was new record: #{previously_new_record?}"

    # Ver cambios específicos
    if saved_change_to_cycle_balance?
      puts "cycle_balance changed from #{saved_change_to_cycle_balance[0]} to #{saved_change_to_cycle_balance[1]}"
    end

    if saved_change_to_historical_balance?
      puts "historical_balance changed from #{saved_change_to_historical_balance[0]} to #{saved_change_to_historical_balance[1]}"
    end

    if saved_change_to_current_balance?
      puts "current_balance changed from #{saved_change_to_current_balance[0]} to #{saved_change_to_current_balance[1]}"
    end
    if balance_changed_or_new_record?
      update_credit_card_current_balance
      push_credit_card_current_balance if should_push_balance?
      update_budget_amount if should_push_balance?
    elsif should_push_balance?
      push_credit_card_current_balance
      update_budget_amount
    end
  end

  def balance_changed_or_new_record?
    new_record? || saved_change_to_cycle_balance? || saved_change_to_historical_balance?
  end

  def should_push_balance?
    new_record? || saved_change_to_current_balance?
  end

  def calculate_minimum_payment
    base_percentage = 0.05
    self.minimum_payment = (current_balance * base_percentage).round(2)

    if credit_card.interest_rate.present?
      interest = current_balance * (credit_card.interest_rate / 100)
      self.minimum_payment += interest
    end

    self.minimum_payment = [minimum_payment, 25.0].max if current_balance > 0
  end
end
