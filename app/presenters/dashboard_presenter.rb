# frozen_string_literal: true

# Presenter para el dashboard financiero del usuario.
# Agrega saldos, tarjetas de crédito y alertas de utilización.
class DashboardPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper

  def initialize(user)
    @user = user
  end

  # Suma de efectivo y fondos de ahorro activos
  def available_balance
    cash_balance + savings_balance
  end

  def available_balance_formatted
    format_currency(available_balance)
  end

  # Desglose: efectivo y cada fondo de ahorro
  def balance_breakdown
    {
      cash: cash_balance,
      cash_formatted: format_currency(cash_balance),
      savings: savings_balance,
      savings_formatted: format_currency(savings_balance),
      savings_detail: savings_breakdown
    }
  end

  # Próximas fechas de corte de tarjetas activas, ordenadas cronológicamente
  def upcoming_card_due_dates(limit: 5)
    entries = credit_card_budgets.filter_map { |budget| build_due_date_entry(budget) }
    entries.sort_by { |c| c[:cutting_date] }.first(limit)
  end

  # Tarjetas con utilización mayor al 30% — incluye monto para bajar al 30%
  def credit_utilization_alerts
    credit_card_budgets
      .select { |budget| alert_triggered?(budget.credit_card) }
      .map { |budget| build_alert_entry(budget) }
  end

  # Suma de saldos actuales de todas las tarjetas activas
  def total_debt
    credit_card_budgets.sum { |b| b.credit_card.current_balance.to_f }
  end

  def total_debt_formatted
    format_currency(total_debt)
  end

  def credit_cards?
    credit_card_budgets.any?
  end

  def savings_funds?
    active_savings_funds.any?
  end

  private

  attr_reader :user

  # Saldo del presupuesto personal (efectivo)
  def cash_balance
    user.budgets.where(personal: true, active: true).sum(:current_amount)
  end

  # Suma del current_amount de todos los presupuestos con fondo de ahorro activo
  def savings_balance
    active_savings_funds.sum { |sf| sf.budget.current_amount.to_f }
  end

  def savings_breakdown
    active_savings_funds.map do |sf|
      { name: sf.budget.name, balance: sf.budget.current_amount,
        balance_formatted: format_currency(sf.budget.current_amount) }
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
    { card_name: budget.name,
      cutting_date: cutting_date,
      payment_due_date: cutting_date + card.payment_due_days.to_i.days,
      days_until_cutting: (cutting_date - Date.current).to_i }
  end

  def alert_triggered?(card)
    card.limit_amount.present? && card.limit_amount.positive? &&
      card.current_balance.to_f.positive? &&
      utilization_percentage(card) > 30
  end

  def build_alert_entry(budget) # rubocop:disable Metrics/MethodLength
    card = budget.credit_card
    utilization = utilization_percentage(card)
    suggested = suggested_payment(card)
    cutting_date = card.cutting_day.present? ? next_cutting_date_for(card) : nil
    { card_name: budget.name,
      utilization_percentage: utilization,
      utilization_status: utilization_status(utilization),
      current_balance: card.current_balance,
      current_balance_formatted: format_currency(card.current_balance),
      suggested_payment: suggested,
      suggested_payment_formatted: format_currency(suggested),
      cutting_date: cutting_date }
  end

  # Siguiente fecha de corte desde hoy para un día de corte dado
  def next_cutting_date_for(card)
    today = Date.current
    day = card.cutting_day.to_i
    if today.day < day
      Date.new(today.year, today.month, day)
    else
      (today + 1.month).change(day: day)
    end
  rescue ArgumentError
    today.end_of_month
  end

  def utilization_percentage(card)
    return 0 if card.limit_amount.nil? || card.limit_amount.zero?

    ((card.current_balance.to_f / card.limit_amount) * 100).round(2)
  end

  # Monto a pagar para reducir la utilización al 30% del límite
  def suggested_payment(card)
    amount = card.current_balance - (card.limit_amount * 0.30)
    [amount, 0].max
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

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end
end
