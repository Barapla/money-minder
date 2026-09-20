# frozen_string_literal: true

# Presenta la vista de detalle de un Budget de tipo debit_card: saldo del dia,
# flujo del mes, saldo dia a dia y lo que esta comprometido antes de la proxima
# nomina. Una cuenta de debito no tiene modelo propio: es el Budget mismo.
class DebitCardPresenter < ApplicationPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper

  MOVEMENTS_SHOWN = 6
  BREAKDOWN_CATEGORIES = 6

  def budget
    @resource
  end

  def name
    @resource.name
  end

  def icon
    @resource.icon.value
  end

  def active?
    @resource.active
  end

  def institution
    financial_product&.institution
  end

  def last_change
    time_ago_in_words(@resource.last_change)
  end

  # ── Saldo ────────────────────────────────────────────────────────────────

  def balance
    @resource.current_amount.to_f
  end

  def balance_formatted
    format_currency(balance)
  end

  # Diferencia contra el cierre de ayer; nil si no hubo movimientos hoy.
  def change_today
    diff = balance - balance_at(Date.yesterday)
    return nil if diff.zero?

    { amount: diff, formatted: format_currency(diff.abs), positive: diff.positive? }
  end

  # ── Flujo del mes ────────────────────────────────────────────────────────

  def month_in
    @month_in ||= month_transactions.select { |item| incoming?(item) }.sum { |item| item.amount.to_f }
  end

  def month_out
    @month_out ||= month_transactions.reject { |item| incoming?(item) }.sum { |item| item.amount.to_f }
  end

  def net_flow
    month_in - month_out
  end

  def month_in_formatted = format_currency(month_in)
  def month_out_formatted = format_currency(month_out)
  def net_flow_formatted = format_currency(net_flow)

  def month_in_count
    month_transactions.count { |item| incoming?(item) }
  end

  def month_out_count
    month_transactions.count { |item| !incoming?(item) }
  end

  def average_daily_spent
    days = [Date.current.day, 1].max
    month_out / days
  end

  def average_daily_spent_formatted
    format_currency(average_daily_spent)
  end

  def month_range_label
    "#{Date.current.beginning_of_month.day} al #{Date.current.day}"
  end

  # ── Compromisos antes de la proxima nomina ───────────────────────────────

  def next_payroll
    @next_payroll ||= PayrollServices::ReminderGenerator
                      .new(@resource.user)
                      .generate(from_date: Date.current, to_date: Date.current + 60.days)
                      .first
  end

  # Pagos de tarjeta con fecha limite antes de la proxima nomina. Son compromisos
  # del usuario, no necesariamente de esta cuenta: la app todavia no guarda desde
  # que cuenta se paga cada tarjeta.
  def commitments
    @commitments ||= card_payments.select { |item| before_payroll?(item[:date]) }
  end

  def commitments_total
    commitments.sum { |item| item[:amount] }
  end

  def commitments_total_formatted
    format_currency(commitments_total)
  end

  def free_to_spend
    balance - commitments_total
  end

  def free_to_spend_formatted
    format_currency(free_to_spend)
  end

  def committed_percent
    return 0 unless balance.positive?

    ((commitments_total / balance) * 100).clamp(0, 100).round
  end

  # Todos los pagos de tarjeta proximos, para el panel lateral.
  def scheduled_payments
    card_payments.first(5)
  end

  def scheduled_total_formatted
    format_currency(card_payments.sum { |item| item[:amount] })
  end

  # ── Saldo dia a dia ──────────────────────────────────────────────────────

  def daily_balances
    from = Date.current.beginning_of_month
    carried = balance_at(from - 1.day)
    (from..Date.current).map do |day|
      closing = closing_balance_by_day[day] || carried
      carried = closing
      { date: day, balance: closing, payroll: payroll_days.include?(day), today: day == Date.current }
    end
  end

  def daily_peak
    daily_balances.map { |point| point[:balance] }.max.to_f
  end

  # ── Movimientos y categorias ─────────────────────────────────────────────

  def movements
    @movements ||= @resource.transactions
                            .includes(:transaction_type, :transaction_history, :category, :icon, :color)
                            .order(transaction_date: :desc, id: :desc)
                            .limit(MOVEMENTS_SHOWN)
                            .map { |transaction| movement_entry(transaction) }
  end

  # En que se va el dinero que sale de esta cuenta, por categoria.
  def spending_breakdown
    build_breakdown(outgoing_by_category.sort_by { |_name, amount| -amount }.first(BREAKDOWN_CATEGORIES))
  end

  private

  def outgoing_by_category
    month_transactions.reject { |item| incoming?(item) }
                      .group_by { |item| item.category&.name || 'Sin categoría' }
                      .transform_values { |list| list.sum { |item| item.amount.to_f } }
  end

  def build_breakdown(rows)
    return [] if rows.empty?

    top = rows.first[1]
    rows.map do |name, amount|
      { name: name, amount_formatted: format_currency(amount),
        width: top.positive? ? ((amount / top) * 100).round : 0,
        share: month_out.positive? ? ((amount / month_out) * 100).round : 0 }
    end
  end

  def movement_entry(transaction)
    presenter = TransactionPresenter.new(transaction)
    { transaction: transaction,
      incoming: incoming?(transaction),
      icon: presenter.icon,
      title: presenter.description.presence || presenter.category,
      category: presenter.category,
      amount_formatted: format_currency(transaction.amount.to_f),
      balance_formatted: format_currency(transaction.post_amount.to_f),
      has_balance: transaction.post_amount.present? }
  end

  def incoming?(transaction)
    !transaction.negative_transaction?
  end

  def month_transactions
    @month_transactions ||= @resource.transactions
                                     .includes(:transaction_type, :category)
                                     .where(transaction_date: Date.current.all_month)
                                     .to_a
  end

  def all_transactions
    @all_transactions ||= @resource.transactions
                                   .includes(:transaction_history)
                                   .order(:transaction_date, :id)
                                   .to_a
  end

  # Saldo al cierre de cada dia con movimientos, tomado del historial.
  def closing_balance_by_day
    @closing_balance_by_day ||= all_transactions.each_with_object({}) do |transaction, map|
      map[transaction.transaction_date.to_date] = transaction.post_amount.to_f
    end
  end

  def balance_at(date)
    last = all_transactions.select { |item| item.transaction_date.to_date <= date }.last
    last&.post_amount.to_f
  end

  def payroll_days
    @payroll_days ||= PayrollServices::ReminderGenerator
                      .new(@resource.user)
                      .generate(from_date: Date.current.beginning_of_month, to_date: Date.current)
                      .map(&:date)
  rescue StandardError
    []
  end

  def before_payroll?(date)
    next_payroll.nil? || date <= next_payroll.date
  end

  def card_payments
    @card_payments ||= @resource.user.budgets
                                .joins(:credit_card)
                                .where(credit_cards: { active: true })
                                .includes(:credit_card)
                                .filter_map { |item| card_payment_entry(item) }
                                .sort_by { |item| item[:date] }
  end

  def card_payment_entry(card_budget)
    card = card_budget.credit_card
    due = card.next_payment_due_date
    return nil unless due

    { name: card_budget.name, date: due, days: (due - Date.current).to_i,
      amount: card.current_debt.to_f, amount_formatted: format_currency(card.current_debt.to_f) }
  end

  def financial_product
    return nil if @resource.financial_product_id.blank?

    @financial_product ||= FinancialCatalogServices::Registry
                           .all_products
                           .find { |product| product.id == @resource.financial_product_id }
  end

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end
end
