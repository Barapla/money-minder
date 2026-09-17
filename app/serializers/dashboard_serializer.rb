# frozen_string_literal: true

# Agrega y serializa el dashboard financiero consolidado para la app movil (FEAT-036/037/038).
class DashboardSerializer
  UPCOMING_PAYMENTS_LIMIT = 10
  UPCOMING_PAYMENTS_WINDOW_DAYS = 30
  AI_INSIGHT_CACHE_TTL = 15.minutes

  def initialize(user, date_range: Date.current.beginning_of_month..Date.current.end_of_month)
    @user = user
    @date_range = date_range
  end

  def as_json(*)
    {
      financial_summary: financial_summary,
      trend_data: trend_data,
      upcoming_payments: upcoming_payments,
      active_budgets: active_budgets,
      credit_cards_summary: credit_cards_summary,
      savings_summary: savings_summary,
      recent_transactions: recent_transactions,
      latest_insight: latest_insight
    }
  end

  private

  attr_reader :user, :date_range

  def financial_summary
    today = Date.current
    dataset = report_filter.report_dataset

    { total_income: dataset[:incomeData].to_f,
      total_expenses: dataset[:expenseData].to_f,
      balance: dataset[:balanceData].to_f,
      month: today.month,
      year: today.year,
      category_breakdown: category_breakdown }
  end

  def report_filter
    ReportFilter.new(user: user, start_date: date_range.begin, end_date: date_range.end, period: 'monthly')
  end

  def category_breakdown
    CategoryBreakdownCalculator.new(user, date_range).call
  end

  def trend_data
    TrendDataCalculator.new(user).call
  end

  def upcoming_payments
    end_date = Date.current + UPCOMING_PAYMENTS_WINDOW_DAYS.days
    user.obligatory_payments
        .includes(:category, recurrence: :frequency_type)
        .filter_map { |payment| upcoming_payment_entry(payment, end_date) }
        .sort_by { |entry| entry[:due_date] }
        .first(UPCOMING_PAYMENTS_LIMIT)
  end

  def upcoming_payment_entry(payment, end_date)
    date = next_due_date_for(payment, end_date)
    return nil unless date

    { id: payment.id,
      title: payment.name.to_s,
      amount: payment.amount.to_f,
      currency: user.currency&.code,
      due_date: date,
      category: payment.category&.name }
  end

  def next_due_date_for(payment, end_date)
    payment.occurrences_in_range(Date.current, end_date).first
  end

  def active_budgets
    BudgetProgressCalculator.new(user).call
  end

  def credit_cards_summary
    CreditCardSummaryCalculator.new(user).call
  end

  def savings_summary
    SavingsSummaryCalculator.new(user).call
  end

  def recent_transactions
    RecentTransactionsCalculator.new(user).call
  end

  def latest_insight
    report = Rails.cache.fetch("dashboard_ai_insight/#{user.id}", expires_in: AI_INSIGHT_CACHE_TTL) do
      AiReport.latest_for_user_and_type(user.id, 'general')
    end
    return nil unless report&.processing_success?

    { id: report.id,
      content: report.summary,
      created_at: report.created_at.iso8601,
      expires_at: report.expires_at&.iso8601 }
  end
end
