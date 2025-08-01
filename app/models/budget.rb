# frozen_string_literal: true

# Budget Model
class Budget < ApplicationRecord
  include Utils::BudgetAttributes
  include ProgressColorIndicator
  include Charteable

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :budget_type_id, presence: true
  validates :color_id, presence: true
  validates :icon_id, presence: true

  # Associations
  has_many :transactions, dependent: :destroy
  has_one :credit_card
  has_one :savings_fund

  belongs_to :user
  belongs_to :budget_type, class_name: 'Catalog', foreign_key: 'budget_type_id'
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  # Solo acepta atributos de credit_card si es tipo credit_card
  accepts_nested_attributes_for :credit_card,
                                allow_destroy: true,
                                update_only: true, reject_if: :should_reject_credit_card?
  accepts_nested_attributes_for :savings_fund,
                                allow_destroy: true,
                                update_only: true, reject_if: :should_reject_savings_fund?

  # Construir credit_card automáticamente
  after_initialize :build_budget_type_if_needed

  after_update :update_debt_amount, if: :saved_change_to_current_amount?

  def expensed_per_frequency(frequency = 'monthly')
    base_query = transactions.joins(:transaction_type)
                            .where(transaction_type: { code: 'expense' })

    case frequency
    when 'monthly'
      generate_monthly_array(base_query)
    when 'weekly'
      generate_weekly_array(base_query)
    when 'daily'
      generate_daily_array(base_query)
    else
      []
    end
  end

  def earned_per_frequency(frequency = 'monthly')
    base_query = transactions.joins(:transaction_type)
                            .where(transaction_type: { code: 'income' })

    case frequency
    when 'monthly'
      generate_monthly_array(base_query)
    when 'weekly'
      generate_weekly_array(base_query)
    when 'daily'
      generate_daily_array(base_query)
    else
      []
    end
  end

  def generate_monthly_array(base_query)
    # PostgreSQL usa TO_CHAR en lugar de DATE_FORMAT
    expenses_by_month = base_query.group("TO_CHAR(transaction_date, 'YYYY-MM')")
                                .sum(:amount)

    # Usar el año actual completo
    current_year = Date.current.year
    start_date = Date.new(current_year, 1, 1)  # 1 de enero
    end_date = Date.new(current_year, 12, 31)  # 31 de diciembre

    result = []
    current_date = start_date

    while current_date <= end_date
      month_key = current_date.strftime('%Y-%m')
      result << (expenses_by_month[month_key] || 0.0)
      current_date = current_date.next_month
    end

    result
  end

  def generate_weekly_array(base_query)
    # PostgreSQL para semanas del año
    expenses_by_week = base_query.group("TO_CHAR(transaction_date, 'IYYY-IW')")
                                .sum(:amount)

    # Usar las últimas 5 semanas
    end_date = Date.current.end_of_week
    start_date = end_date - 4.weeks  # 5 semanas atrás (incluyendo la actual)

    result = []
    current_date = start_date.beginning_of_week

    while current_date <= end_date
      # Usar formato ISO que coincida con PostgreSQL IYYY-IW
      week_key = current_date.strftime('%G-%V')  # %G = año ISO, %V = semana ISO
      result << (expenses_by_week[week_key] || 0.0)
      current_date = current_date.next_week
    end

    result
  end

  def generate_daily_array(base_query)
    # Usar DATE() para agrupar por día
    expenses_by_day = base_query.group("DATE(transaction_date)")
                              .sum(:amount)

    # Usar los últimos 30 días
    end_date = Date.current
    start_date = end_date - 30.days  # 30 días atrás (incluyendo hoy)

    result = []
    (start_date..end_date).each do |date|
      # Buscar directamente por el objeto Date
      amount = expenses_by_day[date] || 0.0
      result << amount
    end

    result
  end

  def get_date_range
    first_transaction = transactions.minimum(:transaction_date)
    last_transaction = transactions.maximum(:transaction_date)

    return nil if first_transaction.nil? || last_transaction.nil?

    {
      start: first_transaction,
      end: last_transaction
    }
  end

  def budget_color
    self.class.progress_color(debt_amount, limit_amount)
  end

  def budget_percentage
    self.class.progress_percentage(debt_amount, limit_amount)
  end

  def budget_status
    self.class.progress_status(debt_amount, limit_amount)
  end

  def transactions_last_days(days = 30)
    transactions
      .where('transaction_date >= ?', days.days.ago)
      .order(transaction_date: :desc)
  end

  def spent_amount_this_month
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', Date.today.at_beginning_of_month)
      .where(transaction_type: { code: %w[expense transfer] })
      .sum(:amount)
  end

  def amount_this_month_by_category(category, transaction_type = 'expense')
    transactions
      .joins(:transaction_type)
      .joins(:category)
      .where('transaction_date >= ?', Date.today.at_beginning_of_month)
      .where(transaction_type: { code: transaction_type })
      .where(category:)
      .sum(:amount)
  end

  # last 15 days average daily spent
  def average_daily_spent
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', 15.days.ago)
      .where(transaction_type: { code: %w[expense transfer] })
      .sum(:amount) / 15.0
  end

  def spent_last_days(days = 30)
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', days.days.ago)
      .where(transaction_type: { code: %w[expense transfer] })
      .sum(:amount)
  end

  def earnings_last_days(days = 30)
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', days.days.ago)
      .where(transaction_type: { code: 'income' })
      .sum(:amount)
  end

  def difference_last_days(days = 30)
    earnings_last_days(days) - spent_last_days(days)
  end

  def last_change
    date_change = updated_at

    last_transaction = transactions.order(transaction_date: :desc).first
    date_change = last_transaction.transaction_date if last_transaction

    date_change
  end

  def categories_with_more_transactions(limit = 5, transaction_type = 'expense',
                                        from_date = Date.today.at_beginning_of_month)
    transactions
      .joins(:transaction_type)
      .joins(:category)
      .where(transaction_type: { code: transaction_type })
      .where('transaction_date >= ?', from_date)
      .group('categories.id')
      .order('COUNT(transactions.id) DESC')
      .limit(limit)
      .select('categories.*, COUNT(transactions.id) AS transactions_count')
  end

  private

  def build_budget_type_if_needed
    # Para registros nuevos, siempre construir credit_card
    # Para registros existentes, solo si es credit_card y no existe
    return unless new_record?
    return build_credit_card if credit_card.nil? && budget_type&.code == 'credit_card'

    build_savings_fund if savings_fund.nil? && budget_type&.code == 'savings_fund'
  end

  def should_reject_credit_card?
    # Rechazar los atributos de credit_card si no es tipo credit_card
    budget_type&.code != 'credit_card'
  end

  def should_reject_savings_fund?
    # Rechazar los atributos de savings_fund si no es tipo savings_fund
    budget_type&.code != 'savings_fund'
  end

  def update_debt_amount
    return if credit_card.nil?

    credit_card.update(debt_amount: credit_card.limit_amount - current_amount)
  end
end
