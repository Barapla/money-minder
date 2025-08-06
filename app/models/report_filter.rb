# frozen_string_literal: true

# app/models/report_filter.rb
class ReportFilter
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :start_date, :date
  attribute :end_date, :date
  attribute :budgets
  attribute :transaction_types
  attribute :period, :string, default: 'monthly'

  # Validaciones opcionales
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  def initialize(attributes = {})
    super
    set_default_dates if start_date.blank? || end_date.blank?
  end

  def transaction_type_per_frequency(transaction_type, frequency = period)
    base_query = filtered_transactions.try(transaction_type)

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

  def categories(limit = nil)
    # Construcción de la query con todos los filtros
    base_query = Category.exclude_categories_by_parent(["Ingresos", "Transferencias"])
                        .joins(:transactions)

    # Aplicar filtro de budgets
    budget_ids = budget_ids_from_filter
    base_query = base_query.where(transactions: { budget_id: budget_ids }) if budget_ids.present?

    # Aplicar filtros de fecha
    base_query = apply_date_filters(base_query)

    # Hacer el group by y order una sola vez con todos los filtros aplicados
    categories = base_query.group('categories.id')
                          .having('SUM(transactions.amount) > 0')
                          .order('SUM(transactions.amount) DESC')
                          .limit(limit)

    # Devolver hash con sumas ya calculadas
    categories.each_with_object({}) do |category, hash|
      sum = base_query.where(categories: { id: category.id })
                    .sum('transactions.amount').abs
      hash[category.name] = sum if sum.positive?
    end
  end

  # Obtener las etiquetas según el período
  def labels_for_period
    case period
    when 'daily'
      (start_date..end_date).map { |date| date.strftime('%d/%m') }
    when 'weekly'
      generate_weekly_labels
    when 'monthly'
      generate_monthly_labels
    else
      []
    end
  end

  private

  def apply_date_filters(query)
    if start_date.present? && end_date.present?
      query.where(transactions: { transaction_date: start_date..end_date })
    elsif start_date.present?
      query.where('transactions.transaction_date >= ?', start_date)
    elsif end_date.present?
      query.where('transactions.transaction_date <= ?', end_date)
    else
      query
    end
end

  def set_default_dates
    case period
    when 'daily'
      self.start_date ||= 30.days.ago.to_date
      self.end_date ||= Date.current
    when 'weekly'
      self.end_date ||= Date.current.end_of_week
      self.start_date ||= end_date - 4.weeks
    when 'monthly'
      self.start_date ||= Date.current.beginning_of_year
      self.end_date ||= Date.current.end_of_year
    end
  end

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'debe ser posterior a la fecha de inicio') if end_date < start_date
  end

  # Query base con filtros de fecha aplicados
  def filtered_transactions
    # Empezar desde Transaction y hacer join con Budget
    base_query = Transaction.joins(:budget)

    # Aplicar filtro de budgets si está presente
    budget_ids = budget_ids_from_filter
    base_query = base_query.where(budget_id: budget_ids)

    # Aplicar filtros de fecha
    if start_date.present? && end_date.present?
      base_query = base_query.where(transaction_date: start_date..end_date)
    elsif start_date.present?
      base_query = base_query.where('transaction_date >= ?', start_date)
    elsif end_date.present?
      base_query = base_query.where('transaction_date <= ?', end_date)
    end

    base_query
  end

  def budget_ids_from_filter
    return Budget.pluck(:id) if budgets.blank?

    case budgets
    when Array
      budgets.present? ? budgets : Budget.pluck(:id)
    when String
      budgets.split(',').map(&:to_i)
    when Budget
      [budgets.id]
    else
      Budget.pluck(:id)
    end
  end

  def generate_monthly_array(base_query)
    expenses_by_month = base_query.group("TO_CHAR(transaction_date, 'YYYY-MM')")
                                .sum(:amount)

    result = []
    current_date = start_date.beginning_of_month

    while current_date <= end_date
      month_key = current_date.strftime('%Y-%m')
      result << (expenses_by_month[month_key] || 0.0)
      current_date = current_date.next_month.beginning_of_month
    end

    result
  end

  def generate_weekly_array(base_query)
    expenses_by_week = base_query.group("TO_CHAR(transaction_date, 'IYYY-IW')")
                                .sum(:amount)

    result = []
    current_date = start_date.beginning_of_week

    while current_date <= end_date
      week_key = current_date.strftime('%G-%V')
      result << (expenses_by_week[week_key] || 0.0)
      current_date = current_date.next_week
    end

    result
  end

  def generate_daily_array(base_query)
    expenses_by_day = base_query.group("DATE(transaction_date)")
                              .sum(:amount)

    result = []
    (start_date..end_date).each do |date|
      amount = expenses_by_day[date] || 0.0
      result << amount
    end

    result
  end

  def generate_monthly_labels
    labels = []
    current_date = start_date.beginning_of_month

    while current_date <= end_date
      labels << I18n.l(current_date, format: '%b')
      current_date = current_date.next_month
    end

    labels
  end

  def generate_weekly_labels
    labels = []
    weeks_count = ((end_date - start_date) / 7).to_i

    weeks_count.downto(1) do |i|
      labels << "Hace #{i} #{'semana'.pluralize(i)}"
    end
    labels << 'Esta semana'

    labels
  end

end
