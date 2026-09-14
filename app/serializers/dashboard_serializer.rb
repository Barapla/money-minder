# frozen_string_literal: true

# Agrega y serializa el dashboard financiero consolidado para la app movil (FEAT-036).
class DashboardSerializer
  UPCOMING_PAYMENTS_LIMIT = 10
  UPCOMING_PAYMENTS_WINDOW_DAYS = 30
  AI_INSIGHT_CACHE_TTL = 15.minutes
  NO_CUTTING_DATE = Date.new(9999, 12, 31)

  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      financial_summary: financial_summary,
      upcoming_payments: upcoming_payments,
      credit_cards: credit_cards_summary,
      latest_ai_insight: latest_ai_insight,
      budgets_summary: budgets_summary
    }
  end

  private

  attr_reader :user

  def financial_summary
    today = Date.current
    dataset = monthly_report_filter(today).report_dataset

    { total_income: dataset[:incomeData].to_f,
      total_expenses: dataset[:expenseData].to_f,
      balance: dataset[:balanceData].to_f,
      month: today.month,
      year: today.year }
  end

  def monthly_report_filter(today)
    ReportFilter.new(user: user, start_date: today.beginning_of_month,
                     end_date: today.end_of_month, period: 'monthly')
  end

  def upcoming_payments
    end_date = Date.current + UPCOMING_PAYMENTS_WINDOW_DAYS.days
    user.obligatory_payments
        .includes(:category, recurrence: :frequency_type)
        .filter_map { |payment| upcoming_payment_entry(payment, end_date) }
        .sort_by { |entry| entry[:payment_due_date] }
        .first(UPCOMING_PAYMENTS_LIMIT)
  end

  def upcoming_payment_entry(payment, end_date)
    date = next_due_date_for(payment, end_date)
    return nil unless date

    { id: payment.id,
      description: payment.name.to_s,
      amount: payment.amount.to_f,
      payment_due_date: date,
      days_until_due: (date - Date.current).to_i,
      category: payment.category&.name }
  end

  def next_due_date_for(payment, end_date)
    if payment.one_time?
      return payment.due_date if payment.due_date&.between?(Date.current, end_date)

      return nil
    end

    payment.recurrence.occurrences_in_range(Date.current, end_date).first
  end

  def credit_cards_summary
    entries = credit_card_budgets.map { |budget| credit_card_entry(budget) }
    entries.sort_by { |entry| entry[:cutting_date] || NO_CUTTING_DATE }
  end

  def credit_card_budgets
    user.budgets
        .joins(:credit_card)
        .where(credit_cards: { active: true })
        .includes(:credit_card)
  end

  def credit_card_entry(budget)
    card = budget.credit_card
    { id: card.id,
      name: budget.name,
      calculated_balance: card.calculated_balance,
      cutting_date: card.next_cutting_date,
      payment_due_date: card.next_payment_due_date }
  end

  def latest_ai_insight
    report = Rails.cache.fetch("dashboard_ai_insight/#{user.id}", expires_in: AI_INSIGHT_CACHE_TTL) do
      AiReport.latest_for_user_and_type(user.id, 'general')
    end
    return nil unless report&.processing_success?

    { summary: report.summary,
      generated_at: report.created_at.iso8601,
      report_type: report.report_type&.code }
  end

  def budgets_summary
    budgets = user.budgets.where(active: true).to_a
    total_budgeted = budgets.sum(&:current_amount).to_f
    total_spent = budgets.sum(&:spent_amount_this_month).to_f
    percentage_used = total_budgeted.positive? ? ((total_spent / total_budgeted) * 100).round(2) : 0.0

    { total_budgeted: total_budgeted,
      total_spent: total_spent,
      percentage_used: percentage_used,
      active_count: budgets.size }
  end
end
