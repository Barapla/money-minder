# frozen_string_literal: true

# Presenta la vista de detalle de un Budget de tipo credit_card: ciclo en curso,
# utilizacion contra el limite, movimientos del ciclo e historial de ciclos.
# El recurso es el Budget; la tarjeta vive en `budget.credit_card`.
class CreditCardPresenter < ApplicationPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper

  # Umbral de utilizacion considerado sano para el historial crediticio.
  HEALTHY_UTILIZATION = 30.0
  HISTORY_LIMIT = 6

  def budget
    @resource
  end

  def card
    @card ||= @resource.credit_card
  end

  def name
    @resource.name
  end

  def icon
    @resource.icon.value
  end

  def active?
    card.active
  end

  # Institucion emisora segun el producto del catalogo, o nil si la tarjeta
  # se creo con la opcion "Otro" (sin producto asociado).
  def institution
    financial_product&.institution
  end

  def limit_amount
    card.limit_amount.to_f
  end

  def limit_amount_formatted
    format_currency(limit_amount)
  end

  def cutting_day
    card.cutting_day
  end

  def last_change
    time_ago_in_words(@resource.last_change)
  end

  # ── Ciclo en curso ───────────────────────────────────────────────────────

  def current_cycle
    @current_cycle ||= card.current_cycle
  end

  def cutting_date
    current_cycle.cutting_date
  end

  # El periodo arranca el dia siguiente al corte anterior, como lo reporta el
  # estado de cuenta ("04-Ago-2026 al 03-Sep-2026").
  def period_start_date
    (cutting_date - 1.month) + 1.day
  end

  def payment_due_date
    current_cycle.payment_due_date
  end

  def days_until_cutting
    (cutting_date - Date.current).to_i
  end

  def cycle_status_code
    current_cycle.lifecycle_status_code
  end

  # Corte ya cerrado que sigue dentro de su ventana de pago, o nil si no hay ninguno.
  # Es el monto realmente exigible hoy, distinto del saldo del ciclo que va corriendo.
  def pending_statement
    @pending_statement ||= begin
      cycle = card.credit_card_cycles.find { |c| c.lifecycle_status_code == 'pending_payment' }
      statement_entry(cycle) if cycle
    end
  end

  def current_balance
    current_cycle.closing_balance.to_f
  end

  def current_balance_formatted
    format_currency(current_balance)
  end

  def cycle_purchases_formatted
    format_currency(current_cycle.purchases.to_f)
  end

  def cycle_payments_formatted
    format_currency(current_cycle.payments.to_f)
  end

  def minimum_payment
    current_cycle.estimated_minimum_payment.to_f
  end

  def statement_balance
    current_cycle.statement_balance
  end

  def minimum_payment_formatted
    format_currency(minimum_payment)
  end

  # Porcentaje del ciclo ya transcurrido, para el marcador de "hoy" en la linea de tiempo.
  def cycle_elapsed_percent
    total = (cutting_date - period_start_date).to_i
    return 0 unless total.positive?

    elapsed = (Date.current - period_start_date).to_i
    ((elapsed.to_f / total) * 100).clamp(0, 100).round
  end

  # ── Utilizacion ──────────────────────────────────────────────────────────

  def available_credit
    card.available_credit.to_f
  end

  def available_credit_formatted
    format_currency(available_credit)
  end

  # Utilizacion que se reportaria si el ciclo en curso cortara hoy. Es una
  # proyeccion, no el historial: el buro ya vio los cortes pasados.
  def utilization_percentage
    return 0.0 if limit_amount <= 0

    (current_balance / limit_amount * 100).round(2)
  end

  def utilization_status
    utilization_status_for(utilization_percentage)
  end

  # Ultimo corte ya cerrado: lo que la tarjeta reporto de verdad.
  def last_cut_utilization
    @last_cut_utilization ||= begin
      cycle = closed_cycles.max_by(&:cutting_date)
      if cycle
        { percent: cycle.utilization_at_cut, date: cycle.cutting_date,
          status: utilization_status_for(cycle.utilization_at_cut) }
      end
    end
  end

  # Saldo maximo que mantiene la utilizacion bajo el 30%.
  def healthy_ceiling
    limit_amount * (HEALTHY_UTILIZATION / 100)
  end

  def healthy_ceiling_formatted
    format_currency(healthy_ceiling)
  end

  # Cuanto puedes gastar todavia sin pasar el techo sano; nil si ya lo cruzaste.
  def room_before_ceiling_formatted
    room = healthy_ceiling - current_balance
    room.positive? ? format_currency(room) : nil
  end

  # ── Movimientos del ciclo ────────────────────────────────────────────────

  def cycle_transactions
    @cycle_transactions ||= current_cycle
                            .credit_card_cycle_transactions
                            .includes(transaction_record: %i[category icon transaction_type])
                            .map(&:transaction_record)
                            .compact
                            .sort_by { |transaction| -transaction.transaction_date.to_time.to_i }
  end

  # Categoria con mayor gasto del ciclo, con su peso sobre el total de compras.
  def top_cycle_category
    expenses = cycle_expenses
    return nil if expenses.empty?

    name, amount = expenses.group_by { |transaction| transaction.category&.name }
                           .transform_values { |list| sum_amounts(list) }
                           .max_by { |_name, sum| sum }
    { name: name, amount_formatted: format_currency(amount), percent: share_of(amount, sum_amounts(expenses)) }
  end

  # ── Historial de ciclos ──────────────────────────────────────────────────

  def cycle_history
    card.credit_card_cycles
        .includes(credit_card_cycle_transactions: { transaction_record: :transaction_type })
        .order(cutting_date: :desc)
        .limit(HISTORY_LIMIT)
        .map { |cycle| history_entry(cycle) }
  end

  # Ultimo ciclo cerrado que se pago completo, para el mensaje de refuerzo del hero.
  def previous_full_payment
    previous = current_cycle.previous_cycle
    return nil unless previous && previous.payment_behavior == 'full_payment'

    { amount_formatted: format_currency(previous.payments.to_f), streak: full_payment_streak }
  end

  private

  def utilization_status_for(percentage)
    return :critical if percentage > 70
    return :warning if percentage > HEALTHY_UTILIZATION

    :healthy
  end

  def closed_cycles
    card.credit_card_cycles.select { |cycle| Date.current > cycle.cutting_date }
  end

  def statement_entry(cycle)
    due_in = (cycle.payment_due_date - Date.current).to_i
    outstanding = cycle.statement_balance - cycle.payments_after_cut
    { cycle: cycle,
      amount: outstanding,
      amount_formatted: format_currency(outstanding),
      minimum_formatted: format_currency(cycle.estimated_minimum_payment.to_f),
      minimum: cycle.estimated_minimum_payment.to_f,
      due_date: cycle.payment_due_date,
      days_until_due: due_in,
      behavior: cycle.payment_behavior }
  end

  def cycle_expenses
    cycle_transactions.select { |transaction| transaction.transaction_type.code == 'expense' }
  end

  def sum_amounts(transactions)
    transactions.sum { |transaction| transaction.amount.to_f }
  end

  def history_entry(cycle)
    { cycle: cycle,
      period_start: (cycle.cutting_date - 1.month) + 1.day,
      cutting_date: cycle.cutting_date,
      status_code: cycle.lifecycle_status_code,
      cut_utilization: cycle.utilization_at_cut,
      current: cycle.id == current_cycle.id,
      behavior: cycle.payment_behavior }.merge(history_amounts(cycle))
  end

  # Cierre = arrastre + compras - pagos. Se expone el monto y su version
  # formateada porque la vista colorea segun el signo (negativo = saldo a favor).
  HISTORY_AMOUNTS = { carried: :historical_balance, purchases: :purchases,
                      payments: :payments, closing: :closing_balance }.freeze

  def history_amounts(cycle)
    HISTORY_AMOUNTS.each_with_object({}) do |(key, column), amounts|
      value = cycle.public_send(column).to_f
      amounts[key] = value
      amounts[:"#{key}_formatted"] = format_currency(value)
    end
  end

  # Ciclos cerrados consecutivos pagados completos, del mas reciente hacia atras.
  def full_payment_streak
    card.credit_card_cycles
        .where('cutting_date < ?', cutting_date)
        .order(cutting_date: :desc)
        .take_while { |cycle| cycle.payment_behavior == 'full_payment' }
        .size
  end

  def financial_product
    return nil if card.financial_product_id.blank?

    @financial_product ||= FinancialCatalogServices::Registry
                           .all_products
                           .find { |product| product.id == card.financial_product_id }
  end

  def share_of(amount, total)
    total.positive? ? (amount / total * 100).round : 0
  end

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end
end
