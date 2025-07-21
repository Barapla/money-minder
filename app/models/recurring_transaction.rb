# frozen_string_literal: true

# RecurringTransaction model
class RecurringTransaction < ApplicationRecord
  belongs_to :transaction_record, class_name: 'Transaction', foreign_key: 'transaction_id'
  belongs_to :user
  # Enums
  enum frequency: {
    daily: 0,
    weekly: 1,
    bi_weekly: 2,      # Cada 2 semanas
    monthly: 3,
    bi_monthly: 4,     # Cada 2 meses
    quarterly: 5,      # Cada 3 meses
    semi_annually: 6,  # Cada 6 meses
    annually: 7
  }

  enum status: {
    active: 0,
    paused: 1,
    completed: 2,
    cancelled: 3
  }

  belongs_to :budget, optional: true # Para asociar a un presupuesto específico
  has_many :generated_transactions, class_name: 'Transaction',
                                    foreign_key: 'recurring_transaction_id', dependent: :nullify

  # Validations
  validates :description, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, allow_blank: true
  validates :frequency, presence: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :due_for_processing, -> { active.where('next_execution_date <= ?', Date.current) }

  # Callbacks
  before_create :set_next_execution_date
  after_update :recalculate_next_execution_date, if: :saved_change_to_frequency?

  # Instance methods
  def next_execution_date
    calculate_next_date(start_date)
  end

  def remaining_executions
    return Float::INFINITY unless end_date

    count = 0
    current_date = start_date

    while current_date <= end_date
      count += 1
      current_date = calculate_next_date(current_date)
    end

    count - generated_transactions.count
  end

  def total_generated_amount
    generated_transactions.sum(:amount)
  end

  def can_execute?
    active? && (end_date.nil? || Date.current <= end_date)
  end

  private

  def calculate_next_date(from_date)
    case frequency
    when 'daily'
      from_date + 1.day
    when 'weekly'
      from_date + 1.week
    when 'bi_weekly'
      from_date + 2.weeks
    when 'monthly'
      from_date + 1.month
    when 'bi_monthly'
      from_date + 2.months
    when 'quarterly'
      from_date + 3.months
    when 'semi_annually'
      from_date + 6.months
    when 'annually'
      from_date + 1.year
    end
  end

  def set_next_execution_date
    self.next_execution_date = calculate_next_date(start_date)
  end

  def recalculate_next_execution_date
    set_next_execution_date
  end
end
