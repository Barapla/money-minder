# frozen_string_literal: true

# Presenta la vista de detalle de un Budget de tipo savings_fund: saldo, peso
# dentro de los fondos del usuario, crecimiento mes a mes y proyeccion segun la
# tasa configurada. El recurso es el Budget; el fondo vive en `budget.savings_fund`.
class SavingsFundPresenter < ApplicationPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper

  GROWTH_MONTHS = 3
  PROJECTION_MONTHS = 12

  def budget
    @resource
  end

  def fund
    @fund ||= @resource.savings_fund
  end

  def name
    @resource.name
  end

  def icon
    @resource.icon.value
  end

  def active?
    fund.active
  end

  def institution
    financial_product&.institution
  end

  def last_change
    time_ago_in_words(@resource.last_change)
  end

  # ── Saldo y meta ─────────────────────────────────────────────────────────

  def balance
    @resource.current_amount.to_f
  end

  def balance_formatted
    format_currency(balance)
  end

  def goal_amount
    fund.goal_amount.to_f
  end

  def goal_formatted
    format_currency(goal_amount)
  end

  def goal?
    goal_amount.positive?
  end

  def progress_percentage
    return 0.0 unless goal?

    ((balance / goal_amount) * 100).clamp(0, 100).round(1)
  end

  def remaining_to_goal_formatted
    remaining = goal_amount - balance
    remaining.positive? ? format_currency(remaining) : nil
  end

  # ── Peso dentro de los fondos del usuario ────────────────────────────────

  # Cuanto de todo lo que tienes en fondos esta en este. Es el dato que si se
  # puede calcular sin distinguir aportes de intereses.
  def share_of_savings
    @share_of_savings ||= begin
      total = sibling_funds.sum { |item| item.current_amount.to_f }
      { percent: total.positive? ? ((balance / total) * 100).round(1) : 0.0,
        total_formatted: format_currency(total),
        count: sibling_funds.size,
        rank: rank_among_funds }
    end
  end

  def biggest?
    share_of_savings[:rank] == 1
  end

  # ── Tasa y proyeccion ────────────────────────────────────────────────────

  def annual_rate
    fund.interest_rate.to_f
  end

  def annual_rate_formatted
    "#{number_with_precision(annual_rate, precision: 2, strip_insignificant_zeros: true)}%"
  end

  # Interes compuesto sobre el saldo de hoy, sin sumar aportes futuros: un aporte
  # no es rendimiento. SavingsFund#projected_balance_in_months si los incluye,
  # porque sirve para planear una meta, no para medir lo que rinde la cuenta.
  def projected_balance
    compounded(PROJECTION_MONTHS)
  end

  def projected_interest
    projected_balance - balance
  end

  def projected_interest_formatted
    format_currency(projected_interest)
  end

  def projected_balance_formatted
    format_currency(projected_balance)
  end

  def projection_date
    Date.current >> PROJECTION_MONTHS
  end

  # Posicion de la tasa de este fondo frente a los demas del usuario.
  def rate_position
    rates = sibling_funds.filter_map { |item| item.savings_fund&.interest_rate&.to_f }
    { best: rates.none? { |rate| rate > annual_rate }, count: rates.size }
  end

  # Fondo con tasa menor y saldo vivo: moverlo aqui rendiria mas al ano.
  def better_here_than
    candidate = lower_rate_funds.max_by { |item| gain_moving_here(item) }
    return nil unless candidate && gain_moving_here(candidate).round >= 1

    { name: candidate.name,
      amount_formatted: format_currency(candidate.current_amount.to_f),
      gain_formatted: format_currency(gain_moving_here(candidate)) }
  end

  # ── Crecimiento ──────────────────────────────────────────────────────────

  # Saldo al cierre de los ultimos meses mas un mes proyectado con la tasa.
  def monthly_balances
    months = (0...GROWTH_MONTHS).map { |back| Date.current.beginning_of_month << back }.reverse
    points = months.map { |month| { label: month, balance: balance_at(month.end_of_month), projected: false } }
    points << { label: Date.current.beginning_of_month >> 1, balance: compounded(1), projected: true }
  end

  def growth?
    monthly_balances.any? { |point| point[:balance].positive? }
  end

  # ── Movimientos ──────────────────────────────────────────────────────────

  def movements
    @movements ||= @resource.transactions
                            .includes(:transaction_type, :transaction_history, :category)
                            .order(transaction_date: :desc, id: :desc)
                            .map { |transaction| movement_entry(transaction) }
  end

  private

  def compounded(months)
    balance * ((1 + fund.monthly_rate)**months)
  end

  def rank_among_funds
    sibling_funds.count { |item| item.current_amount.to_f > balance } + 1
  end

  def lower_rate_funds
    sibling_funds.select do |item|
      item.id != @resource.id && item.current_amount.to_f.positive? &&
        item.savings_fund&.interest_rate.to_f < annual_rate
    end
  end

  def movement_entry(transaction)
    incoming = !transaction.negative_transaction?
    { transaction: transaction,
      incoming: incoming,
      amount_formatted: format_currency(transaction.amount.to_f),
      balance_formatted: format_currency(transaction.post_amount.to_f),
      has_balance: transaction.post_amount.present? }
  end

  # Saldo al cierre de una fecha, tomado del historial de la ultima transaccion
  # anterior o igual a ese dia. Sin historial cae en 0 (fondo recien creado).
  def balance_at(date)
    last = @resource.transactions
                    .includes(:transaction_history)
                    .where(transaction_date: ..date)
                    .max_by { |transaction| [transaction.transaction_date, transaction.id] }
    last&.post_amount.to_f
  end

  def gain_moving_here(other)
    rate_gap = annual_rate - other.savings_fund&.interest_rate.to_f
    other.current_amount.to_f * rate_gap / 100
  end

  def sibling_funds
    @sibling_funds ||= @resource.user.budgets
                                .joins(:budget_type)
                                .where(catalogs: { code: 'savings_fund' }, budgets: { active: true })
                                .includes(:savings_fund)
                                .to_a
  end

  def financial_product
    return nil if fund.financial_product_id.blank?

    @financial_product ||= FinancialCatalogServices::Registry
                           .all_products
                           .find { |product| product.id == fund.financial_product_id }
  end

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end
end
