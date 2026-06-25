# frozen_string_literal: true

# Presenter para el dashboard financiero del usuario.
# Agrega saldos, tarjetas de crédito/débito, alertas de utilización, nómina y presupuesto del mes.
class DashboardPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper

  def initialize(user)
    @user = user
  end

  # Retorna datos de la próxima nómina o nil si el usuario no tiene información laboral.
  def next_payroll_info
    return nil unless payroll_configured?

    reminder = next_payroll_reminder
    build_payroll_info(reminder) if reminder
  end

  def payroll_configured?
    user.employment_information.present? && user.payroll_profile.present?
  end

  # Retorna top 8 categorías de gasto del mes actual, ordenadas de mayor a menor.
  # La barra muestra la proporción relativa al gasto máximo entre las categorías.
  def monthly_budget_summary
    @monthly_budget_summary ||= build_budget_summary(monthly_expense_rows)
  end

  def monthly_budget_summary?
    monthly_budget_summary.any?
  end

  # Suma de efectivo, tarjetas de débito y fondos de ahorro activos
  def available_balance
    cash_balance + debit_balance + savings_balance
  end

  def available_balance_formatted
    format_currency(available_balance)
  end

  # Desglose: efectivo, tarjetas de débito y cada fondo de ahorro
  def balance_breakdown
    {
      cash: cash_balance,
      cash_formatted: format_currency(cash_balance),
      debit: debit_balance,
      debit_formatted: format_currency(debit_balance),
      debit_detail: debit_breakdown,
      savings: savings_balance,
      savings_formatted: format_currency(savings_balance),
      savings_detail: savings_breakdown
    }
  end

  # Fechas de corte de todas las tarjetas activas, ordenadas cronológicamente
  def upcoming_card_due_dates
    entries = credit_card_budgets.filter_map { |budget| build_due_date_entry(budget) }
    entries.sort_by { |c| c[:cutting_date] }
  end

  # Tarjetas con utilización mayor al 30% — incluye monto para bajar al 30%
  def credit_utilization_alerts
    credit_card_budgets
      .select { |budget| alert_triggered?(budget.credit_card) }
      .map { |budget| build_alert_entry(budget) }
  end

  # Suma de deudas actuales de todas las tarjetas activas (ciclo vigente)
  def total_debt
    credit_card_budgets.sum { |b| b.credit_card&.current_debt.to_f }
  end

  def total_debt_formatted
    format_currency(total_debt)
  end

  # Deuda desglosada por tarjeta
  def debt_breakdown
    credit_card_budgets.filter_map do |budget|
      debt = budget.credit_card&.current_debt.to_f
      next if debt.zero?

      { card_name: budget.name, debt: debt, debt_formatted: format_currency(debt) }
    end
  end

  # Metas de ahorro activas con asignación automática de saldo disponible por prioridad
  def prioritized_saving_goals
    allocations = SavingGoalServices::PriorityAllocator.new(user).allocate
    active_saving_goals.map { |goal| build_goal_entry(goal, allocations[goal.id] || 0) }
  end

  def saving_goals?
    active_saving_goals.any?
  end

  def credit_cards?
    credit_card_budgets.any?
  end

  def savings_funds?
    active_savings_funds.any?
  end

  def debit_cards?
    active_debit_budgets.any?
  end

  # Cuenta y total mensual de gastos recurrentes activos
  def recurring_expenses_summary
    expenses = active_recurring_expenses
    { count: expenses.size, monthly_total: calculate_monthly_total(expenses) }
  end

  def recurring_expenses?
    active_recurring_expenses.any?
  end

  # Próximos pagos obligatorios en los siguientes 30 días (máx. 10)
  def upcoming_obligatory_payments
    @upcoming_obligatory_payments ||= begin
      end_date = Date.current + 30.days
      ops = user.obligatory_payments.includes(recurrence: :frequency_type)
      instances = ops.flat_map { |op| obligatory_payment_instances(op, end_date) }
      instances.sort_by { |i| i[:date] }.take(10)
    end
  end

  private

  attr_reader :user

  def active_saving_goals
    @active_saving_goals ||= user.saving_goals.where(status: :active).order(:priority_order)
  end

  def build_goal_entry(goal, allocated)
    {
      saving_goal: goal,
      target_amount: goal.target_amount,
      allocated_amount: allocated,
      allocated_formatted: format_currency(allocated),
      target_formatted: format_currency(goal.target_amount),
      progress_percentage: (allocated.to_f / goal.target_amount * 100).clamp(0, 100).round(1)
    }
  end

  # Saldo del presupuesto personal (efectivo)
  def cash_balance
    user.budgets.where(personal: true, active: true).sum(:current_amount)
  end

  # Suma de saldos de tarjetas de débito activas
  def debit_balance
    active_debit_budgets.sum(:current_amount)
  end

  def debit_breakdown
    active_debit_budgets.map do |budget|
      { name: budget.name, balance: budget.current_amount,
        balance_formatted: format_currency(budget.current_amount || 0) }
    end
  end

  def active_debit_budgets
    @active_debit_budgets ||= user.budgets
                                  .joins(:budget_type)
                                  .where(budgets: { active: true })
                                  .where(budget_type: { code: 'debit_card' })
  end

  # Suma del current_amount de todos los presupuestos con fondo de ahorro activo
  def savings_balance
    active_savings_funds.sum { |sf| sf.budget&.current_amount.to_f || 0 }
  end

  def savings_breakdown
    active_savings_funds.filter_map do |sf|
      next unless sf.budget

      { name: sf.budget.name, balance: sf.budget.current_amount,
        balance_formatted: format_currency(sf.budget.current_amount || 0) }
    end
  end

  def active_savings_funds
    @active_savings_funds ||= SavingsFund.joins(:budget)
                                         .where(budgets: { user_id: user.id, active: true })
                                         .where(active: true)
                                         .includes(:budget)
  end

  def credit_card_budgets
    @credit_card_budgets ||= user.budgets
                                 .joins(:credit_card)
                                 .where(credit_cards: { active: true })
                                 .includes(:credit_card)
  end

  def build_due_date_entry(budget)
    card = budget.credit_card
    return nil unless card.cutting_day.present?

    cutting_date = next_cutting_date_for(card)
    current_debt = card.current_debt.to_f
    { card_name: budget.name,
      cutting_date: cutting_date,
      payment_due_date: cutting_date + card.payment_due_days.to_i.days,
      days_until_cutting: (cutting_date - Date.current).to_i,
      current_debt: current_debt,
      current_debt_formatted: format_currency(current_debt) }
  end

  # Tarjetas con deuda cero no generan alertas porque su utilización no representa riesgo.
  def alert_triggered?(card)
    card.limit_amount.present? && card.limit_amount.positive? &&
      card.current_debt.to_f.positive? &&
      utilization_percentage(card) > 30
  end

  def build_alert_entry(budget) # rubocop:disable Metrics/MethodLength
    card = budget.credit_card
    utilization = utilization_percentage(card)
    suggested = suggested_payment(card)
    cutting_date = card.cutting_day.present? ? next_cutting_date_for(card) : nil
    current_balance = card.current_debt.to_f
    { card_name: budget.name,
      utilization_percentage: utilization,
      utilization_status: utilization_status(utilization),
      current_balance: current_balance,
      current_balance_formatted: format_currency(current_balance),
      suggested_payment: suggested,
      suggested_payment_formatted: format_currency(suggested),
      cutting_date: cutting_date }
  end

  # Siguiente fecha de corte desde hoy para un día de corte dado.
  # Usa >> para avanzar al mes siguiente y limita el día al último del mes
  # para evitar fechas inválidas (ej: 31 en febrero).
  def next_cutting_date_for(card)
    return nil if card.cutting_day.blank?

    today = Date.current
    day = card.cutting_day.to_i
    if today.day < day
      Date.new(today.year, today.month, day)
    else
      next_month = today >> 1
      Date.new(next_month.year, next_month.month, [day, next_month.end_of_month.day].min)
    end
  end

  def utilization_percentage(card)
    return 0 if card.limit_amount.nil? || card.limit_amount <= 0

    ((card.current_debt.to_f / card.limit_amount) * 100).round(2)
  end

  # Monto a pagar para reducir la utilización al 30% del límite
  def suggested_payment(card)
    amount = card.current_debt.to_f - (card.limit_amount * 0.30)
    [amount, 0].max
  end

  def next_payroll_reminder
    PayrollServices::ReminderGenerator
      .new(user)
      .generate(from_date: Date.current, to_date: Date.current + 60.days)
      .first
  end

  def build_payroll_info(reminder)
    days = (reminder.date - Date.current).to_i
    { net_amount: reminder.net_amount,
      net_amount_formatted: format_currency(reminder.net_amount),
      payment_date: reminder.date,
      days_until: days,
      periodicity_label: reminder.periodicity_label,
      next_period_label: reminder.next_period_label,
      coming_soon: days <= 7 }
  end

  def monthly_expense_rows
    start_date = Date.current.beginning_of_month
    end_date   = Date.current.end_of_month
    user.transactions
        .joins(:transaction_type)
        .joins(:category)
        .where(transaction_type: { code: 'expense' })
        .where(transaction_date: start_date..end_date)
        .group('categories.id', 'categories.name')
        .sum('ABS(transactions.amount)')
  end

  # Construye el resumen de presupuesto a partir de filas agrupadas por categoría.
  # El porcentaje es relativo al gasto máximo entre las categorías (mayor = 100%).
  def build_budget_summary(rows)
    return [] if rows.empty?

    sorted = rows.sort_by { |_key, amount| -amount }.first(8)
    max_amount = sorted.first[1].to_f
    sorted.map { |(_, name), amount| budget_row(name, amount, max_amount) }
  end

  def budget_row(category_name, amount, max_amount)
    pct = max_amount.positive? ? ((amount.to_f / max_amount) * 100).round : 0
    { category_name: category_name,
      amount: amount.to_f,
      amount_formatted: format_currency(amount.to_f),
      progress_percent: pct,
      status: budget_status(pct) }
  end

  # :healthy (<30%), :warning (30-70%), :critical (>70%)
  def utilization_status(percentage)
    if percentage <= 30
      :healthy
    elsif percentage <= 70
      :warning
    else
      :critical
    end
  end

  def budget_status(progress)
    return :danger if progress >= 90
    return :warning if progress >= 70

    :safe
  end

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end

  MONTHLY_FREQUENCY_MULTIPLIERS = {
    'daily' => 30, 'weekly' => 4.33, 'bi_weekly' => 2.17, 'monthly' => 1,
    'bi_monthly' => 0.5, 'quarterly' => (1.0 / 3), 'semi_annually' => (1.0 / 6),
    'annually' => (1.0 / 12)
  }.freeze

  def active_recurring_expenses
    @active_recurring_expenses ||= begin
      type_id = expense_transaction_type_id
      return [] if type_id.nil?

      user.recurring_transactions
          .active
          .where("transaction_options->>'transaction_type_id' = ?", type_id.to_s)
    end
  end

  def expense_transaction_type_id
    @expense_transaction_type_id ||= Catalog.by_group_and_code('transaction_types', 'expense')&.id
  end

  def calculate_monthly_total(recurring_transactions)
    recurring_transactions.sum do |recurrence|
      amount = recurrence.transaction_options['amount'].to_f
      multiplier = MONTHLY_FREQUENCY_MULTIPLIERS.fetch(recurrence.frequency, 1)
      amount * multiplier
    end
  end

  def obligatory_payment_instances(payment, end_date)
    recurrence = payment.recurrence
    return [] if recurrence.nil?

    recurrence.occurrences_in_range(Date.current, end_date)
              .map { |date| build_obligatory_instance(payment, date) }
  end

  def build_obligatory_instance(payment, date)
    { date: date,
      description: payment.name.to_s,
      amount: payment.amount.to_f,
      amount_formatted: format_currency(payment.amount.to_f) }
  end
end
