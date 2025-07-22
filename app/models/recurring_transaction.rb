# frozen_string_literal: true

# RecurringTransaction model
class RecurringTransaction < ApplicationRecord
  belongs_to :user
  # Enums
  enum frequency: %i[daily weekly bi_weekly monthly bi_monthly quarterly semi_annually annually]

  enum status: %i[active paused completed cancelled], _default: :active

  belongs_to :budget, optional: true # Para asociar a un presupuesto específico
  has_many :generated_transactions, class_name: 'Transaction',
                                    foreign_key: 'recurring_transaction_id', dependent: :nullify

  # Validations
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, allow_blank: true
  validates :frequency, presence: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :due_for_processing, -> { active.where('next_execution_date <= ?', Date.current) }

  # Callbacks
  before_create :set_next_execution_date
  after_create :define_first_transaction, if: :created_by_transaction?
  after_update :recalculate_next_execution_date, if: :saved_change_to_frequency?

  def self.frequency_options_for_select
    {
      'daily' => '📅 Diario',
      'weekly' => '📅 Semanal',
      'bi_weekly' => '📅 Quincenal',
      'monthly' => '📅 Mensual',
      'bi_monthly' => '📅 Bimestral',
      'quarterly' => '📅 Trimestral',
      'semi_annually' => '📅 Semestral',
      'annually' => '📅 Anual'
    }.map { |key, label| [label, key] }
  end

  def define_first_transaction
    transaction = ::Transaction.find(transaction_options['id'])

    transaction.update(recurring_transaction: self)
    self.execution_count = 1
  end

  # Instance methods
  def next_execution_date
    calculate_next_date(start_date)
  end

  def budget
    Budget.find(transaction_options['budget_id']) if transaction_options['budget_id'].present?
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

  def created_by_transaction?
    transaction_options['id'].present?
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
