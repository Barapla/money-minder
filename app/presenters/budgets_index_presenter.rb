# frozen_string_literal: true

# Presenta el index de presupuestos: los totales de arriba y las cuentas
# agrupadas por lo que son (uso diario, inversion, plazo fijo) mas la tabla de
# tarjetas de credito. Las cuentas en ceros se mandan al final de su grupo.
class BudgetsIndexPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper

  DAILY_USE_TYPES = %w[cash debit_card].freeze
  # Orden de los chips del filtro. Un tipo sin cuentas igual se muestra con su
  # contador en cero, como en el diseño ("Plazo fijo · 0").
  FILTER_TYPES = %w[cash debit_card savings_fund term_saving credit_card].freeze
  HEALTHY_UTILIZATION = 30.0

  def initialize(user)
    @user = user
  end

  def any?
    budgets.any?
  end

  # ── Totales ──────────────────────────────────────────────────────────────

  def money_total
    @money_total ||= liquidity.cash_balance.to_f + liquidity.debit_balance.to_f + liquidity.savings_balance.to_f
  end

  def debt_total
    @debt_total ||= cards.sum { |item| item[:debt] }
  end

  def net_worth
    money_total - debt_total
  end

  # Reparto de la barra del patrimonio: que parte de lo que mueves es tuyo y
  # que parte es deuda. Sin deuda la barra va entera en verde.
  def money_share_of_total
    total = money_total + debt_total
    return 100.0 unless total.positive?

    ((money_total / total) * 100).round(1)
  end

  def money_count
    money_budgets.size
  end

  def cards_count
    cards.size
  end

  def accounts_count
    budgets.size
  end

  # Suma de los limites de todas las tarjetas activas.
  def credit_limit_total
    @credit_limit_total ||= cards.sum { |item| item[:limit] }
  end

  def total_utilization
    return 0.0 unless credit_limit_total.positive?

    ((debt_total / credit_limit_total) * 100).round(1)
  end

  def utilization_healthy?
    total_utilization <= HEALTHY_UTILIZATION
  end

  # Rendimiento anual estimado con la tasa configurada en cada fondo con saldo.
  def annual_yield
    fondeados = investment_accounts.reject { |item| item[:zero] }
    fondeados.sum { |item| item[:balance] * item[:rate].to_f / 100 }
  end

  def yielding_funds_count
    investment_accounts.count { |item| !item[:zero] }
  end

  # ── Compromisos ──────────────────────────────────────────────────────────

  def next_payroll
    @next_payroll ||= PayrollServices::ReminderGenerator
                      .new(user)
                      .generate(from_date: Date.current, to_date: Date.current + 60.days)
                      .first
  end

  def due_soon
    @due_soon ||= cards.select { |item| item[:debt].positive? && due_before_payroll?(item[:payment_date]) }
  end

  def due_soon_total
    due_soon.sum { |item| item[:debt] }
  end

  def free_to_spend
    liquidity.debit_balance.to_f - due_soon_total
  end

  # ── Grupos ───────────────────────────────────────────────────────────────

  def daily_use_accounts
    @daily_use_accounts ||= sorted(money_budgets.select { |b| DAILY_USE_TYPES.include?(code_of(b)) }
                                                .map { |b| account_entry(b) })
  end

  def investment_accounts
    @investment_accounts ||= sorted(money_budgets.select { |b| code_of(b) == 'savings_fund' }
                                                .map { |b| account_entry(b) })
  end

  def term_accounts
    @term_accounts ||= sorted(budgets.select { |b| code_of(b) == 'term_saving' }.map { |b| account_entry(b) })
  end

  # La tabla abre mostrando solo las que deben; el resto se pliega en una fila.
  def cards_with_debt
    cards.reject { |item| item[:debt].zero? }
  end

  def cards_without_debt
    cards.select { |item| item[:debt].zero? }
  end

  def unused_credit_line
    cards_without_debt.sum { |item| item[:limit] }
  end

  # Tarjetas por encima del 30% de su linea, que es lo que mira el buro.
  def cards_over_limit
    cards.select { |item| item[:utilization] > HEALTHY_UTILIZATION }
  end

  # Si pagaras completa la mas comprometida, cual seria la utilizacion mas alta
  # que te quedaria.
  def utilization_without(card)
    rest = cards.reject { |item| item[:budget].id == card[:budget].id }
    rest.map { |item| item[:utilization] }.max.to_f
  end

  def cards
    @cards ||= budgets.select { |b| code_of(b) == 'credit_card' && b.credit_card }
                      .map { |b| card_entry(b) }
                      .sort_by { |item| card_sort_key(item) }
  end

  # [[codigo, cantidad]] para los chips, incluyendo los tipos que no tienes.
  def type_counts
    counts = budgets.group_by { |b| code_of(b) }.transform_values(&:size)
    FILTER_TYPES.map { |code| [code, counts.fetch(code, 0)] }
  end

  # Etiqueta corta de estado para cada cuenta, como en el diseño.
  def status_for(account)
    return :unused if account[:zero] && DAILY_USE_TYPES.include?(account[:code])
    return :unfunded if account[:zero]
    return :lower_yield if account[:code] == 'savings_fund' && lowest_yield?(account)
    return :investment if account[:code] == 'savings_fund'

    :daily
  end

  # Cuanto ganarias al año moviendo ese saldo al fondo de mejor tasa.
  def move_suggestion(account)
    best = best_rate_fund
    return nil unless best && account[:rate] && best[:rate] > account[:rate]

    gain = account[:balance] * (best[:rate] - account[:rate]) / 100
    return nil unless gain.round >= 1

    { to: best[:name], gain_formatted: format_currency(gain) }
  end

  def group_total(accounts)
    accounts.sum { |item| item[:balance] }
  end

  def group_share(accounts)
    return 0 unless money_total.positive?

    ((group_total(accounts) / money_total) * 100).round
  end

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end

  private

  attr_reader :user

  def best_rate_fund
    @best_rate_fund ||= investment_accounts.reject { |item| item[:zero] }
                                           .max_by { |item| item[:rate].to_f }
  end

  def lowest_yield?(account)
    funded = investment_accounts.reject { |item| item[:zero] }
    return false unless funded.size > 1

    (account[:rate].to_f - funded.map { |item| item[:rate].to_f }.min).abs < 0.001
  end

  def liquidity
    @liquidity ||= LiquidityServices::Calculator.new(user)
  end

  def budgets
    @budgets ||= user.budgets.where(active: true)
                     .includes(:budget_type, :icon, :color, :credit_card, :savings_fund)
                     .order(:name)
                     .to_a
  end

  def money_budgets
    @money_budgets ||= budgets.reject { |b| %w[credit_card term_saving].include?(code_of(b)) }
  end

  def code_of(budget)
    budget.budget_type&.code
  end

  # Con saldo primero; las cuentas en ceros al final, como pide el diseño.
  def sorted(entries)
    entries.sort_by { |item| [item[:zero] ? 1 : 0, -item[:balance]] }
  end

  def card_sort_key(item)
    [item[:debt].positive? ? 0 : 1, item[:payment_date] || Date.new(9999)]
  end

  def account_entry(budget)
    balance = budget.current_amount.to_f
    { budget: budget, name: budget.name, icon: budget.icon&.value, code: code_of(budget),
      balance: balance, balance_formatted: format_currency(balance), zero: balance <= 0,
      share: share_of_money(balance), rate: budget.savings_fund&.interest_rate&.to_f,
      month_in: month_income_for(budget) }
  end

  def share_of_money(balance)
    money_total.positive? ? ((balance / money_total) * 100).round(1) : 0.0
  end

  def card_entry(budget)
    card = budget.credit_card
    due = card.next_payment_due_date
    { budget: budget, name: budget.name, icon: budget.icon&.value,
      cutting_day: card.cutting_day, payment_date: due,
      days: due && (due - Date.current).to_i,
      minimum_formatted: format_currency(card.current_cycle&.estimated_minimum_payment.to_f) }
      .merge(card_amounts(card))
  end

  def card_amounts(card)
    debt = card.current_debt.to_f
    limit = card.limit_amount.to_f
    { debt: debt, debt_formatted: format_currency(debt),
      limit: limit, limit_formatted: format_currency(limit),
      utilization: limit.positive? ? ((debt / limit) * 100).round(1) : 0.0 }
  end

  # Lo que entró al presupuesto este mes. En un fondo suele ser el rendimiento,
  # pero la app todavía no distingue un abono de interés de cualquier otro
  # ingreso, así que se etiqueta como entrada y no como interés.
  def month_income_for(budget)
    month_income[budget.id].to_f
  end

  def month_income
    @month_income ||= user.transactions
                          .joins(:transaction_type)
                          .where(transaction_date: Date.current.all_month)
                          .where(catalogs: { code: 'income' })
                          .group(:budget_id)
                          .sum(:amount)
  end

  def due_before_payroll?(date)
    return false if date.nil?
    return date <= Date.current + 7.days if next_payroll.nil?

    date <= next_payroll.date
  end
end
