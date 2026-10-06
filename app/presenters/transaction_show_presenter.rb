# frozen_string_literal: true

# Presenta el detalle de una transaccion: el impacto en el saldo del presupuesto,
# el ciclo de tarjeta en el que cayo, el peso dentro de su categoria y los
# metadatos.
#
# `pre_amount`/`post_amount` NO son columnas de `transactions`: salen de
# `transaction_history`, que se crea en un after_create. En filas viejas puede no
# existir, asi que todo lo que dependa de ellas tiene que aguantar el nil.
class TransactionShowPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper

  HEALTHY_UTILIZATION = 30.0
  TOP_CATEGORY_ROWS = 3

  def initialize(transaction)
    @transaction = transaction
  end

  attr_reader :transaction

  delegate :description, :category, :budget, :currency, :uuid, :amount,
           :transaction_date, :created_at, :updated_at, to: :transaction

  # ── Identidad ────────────────────────────────────────────────────────────

  def title
    description.presence || category&.name
  end

  def icon
    transaction.icon&.value
  end

  def type_code
    transaction.transaction_type&.code
  end

  def type_label
    transaction.transaction_type&.value
  end

  def negative?
    transaction.negative_transaction?
  end

  def signed_amount
    negative? ? -amount.to_f : amount.to_f
  end

  def amount_formatted
    format_signed(signed_amount)
  end

  def date_long
    I18n.l(transaction_date, format: :long) if transaction_date
  end

  def month_label
    I18n.l(transaction_date.beginning_of_month, format: :month_year) if transaction_date
  end

  # ── Impacto en el presupuesto ────────────────────────────────────────────

  # Sin transaction_history no hay antes/despues que mostrar.
  def impact?
    pre_amount.present? && post_amount.present?
  end

  def pre_amount
    transaction.pre_amount
  end

  def post_amount
    transaction.post_amount
  end

  def credit_card?
    budget&.budget_type&.code == 'credit_card'
  end

  def credit_card
    budget&.credit_card
  end

  def limit_amount
    credit_card&.limit_amount.to_f
  end

  # OJO: en una tarjeta `Budget#current_amount` (y por tanto pre/post_amount) NO
  # es la deuda sino el CREDITO DISPONIBLE — es lo mismo que
  # CreditCard#available_credit. La deuda es la resta contra el limite, que es
  # justo como CreditCard#current_debt da su numero.
  def balance_before
    balance_of(pre_amount)
  end

  def balance_after
    balance_of(post_amount)
  end

  # Lo que este movimiento le movio al saldo que se muestra arriba.
  def balance_delta
    balance_after - balance_before
  end

  def utilization_before
    percent_of_limit(balance_before)
  end

  def utilization_after
    percent_of_limit(balance_after)
  end

  # Lo que esta transaccion sola pesa contra la linea. Es la pregunta de esta
  # pagina: cuanto de tu credito se comio ESTE cargo.
  def share_of_limit
    percent_of_limit(amount)
  end

  def utilization_delta
    (utilization_after - utilization_before).round(1)
  end

  # La barra va apilada sobre la linea completa (0–100%): primero donde estaba la
  # deuda y encima lo que movio este movimiento, como tramo aparte y visible.
  # Un pago baja la deuda, asi que el tramo se pinta en verde y arranca donde
  # queda el saldo nuevo.
  def utilization_segments
    base = [utilization_before, utilization_after].min.clamp(0, 100)
    change = utilization_delta.abs.clamp(0, 100 - base)

    { base:, change:, direction: utilization_delta.negative? ? :down : :up }
  end

  def healthy_ceiling
    HEALTHY_UTILIZATION
  end

  # Un abono a la tarjeta baja la deuda: no es un cargo y no se rotula como tal.
  def reduces_debt?
    balance_delta.negative?
  end

  def utilization_healthy?
    utilization_after <= HEALTHY_UTILIZATION
  end

  # ── Ciclo de tarjeta ─────────────────────────────────────────────────────

  def cycle
    return @cycle if defined?(@cycle)

    @cycle = transaction.credit_card_cycle_transaction&.credit_card_cycle
  end

  def cycle_status_code
    cycle&.lifecycle_status_code
  end

  def cycle_start
    cycle&.period_start_date || cycle&.cutting_date&.prev_month
  end

  def cycle_end
    cycle&.cutting_date
  end

  def payment_due_date
    cycle&.payment_due_date
  end

  # Posicion de una fecha dentro del ciclo, en porcentaje, recortada a [0, 100]
  # para que un cargo fuera de rango no se salga de la barra.
  def position_in_cycle(date)
    span = cycle_span
    return 0.0 if date.nil? || span.nil?

    (((date - cycle_start).to_i / span.to_f) * 100).clamp(0.0, 100.0).round(1)
  end

  def charge_position
    position_in_cycle(transaction_date)
  end

  def today_position
    position_in_cycle(Date.current)
  end

  # ── Categoria ────────────────────────────────────────────────────────────

  # A diferencia de Transaction#spent_amount_the_month_by_category, que solo mira
  # el presupuesto de esta transaccion, aqui se cuenta la categoria en todas las
  # cuentas: la misma categoria suele repartirse entre varias.
  def category_transactions
    @category_transactions ||= transaction.user.transactions
                                          .where(category_id: transaction.category_id,
                                                 transaction_type_id: transaction.transaction_type_id,
                                                 transaction_date: month_range)
                                          .order(amount: :desc)
                                          .to_a
  end

  def category_total
    @category_total ||= category_transactions.sum { |item| item.amount.to_f }
  end

  def category_share
    return 0.0 unless category_total.positive?

    ((amount.to_f / category_total) * 100).round(1)
  end

  def category_top
    category_transactions.first(TOP_CATEGORY_ROWS)
  end

  def category_rest_total
    category_total - category_top.sum { |item| item.amount.to_f }
  end

  def category_average
    return 0.0 if category_transactions.empty?

    category_total / category_transactions.size
  end

  # Cuanto se sale este cargo del promedio de su categoria, en porcentaje.
  def versus_average
    return 0 unless category_average.positive?

    (((amount.to_f - category_average) / category_average) * 100).round
  end

  def share_of_category(item)
    return 0.0 unless category_total.positive?

    ((item.amount.to_f / category_total) * 100).round(1)
  end

  # ── Recurrencia ──────────────────────────────────────────────────────────

  def recurring
    transaction.recurring_transaction
  end

  def recurring?
    recurring.present?
  end

  # Etiqueta de la frecuencia: el enum guarda la clave y el modelo ya tiene el
  # mapa de rotulos para el select, con emoji incluido que aqui sobra.
  def frequency_label
    return nil unless recurring

    label = RecurringTransaction.frequency_options_for_select.to_h.invert[recurring.frequency]
    label&.sub('📅 ', '')&.downcase
  end

  # ── Relacionadas ─────────────────────────────────────────────────────────

  # El espejo del traspaso, mas los demas movimientos del mismo dia en la misma
  # categoria: lo que el diseño llama "el mismo dia cargaste la otra linea".
  def related_transactions
    @related_transactions ||= begin
      mirror = [transaction.related_transaction].compact
      mirror + same_day_transactions(mirror.map(&:id))
    end
  end

  def related_total
    ([transaction] + related_transactions).sum { |item| item.amount.to_f }
  end

  # ── Deudas ───────────────────────────────────────────────────────────────

  # Lo que este movimiento abona. Puede repartirse entre varias, y el monto
  # aplicado no tiene por que ser el del movimiento.
  def debt_allocations
    @debt_allocations ||= transaction.debt_allocations.includes(:debt).to_a
  end

  def allocated_total
    debt_allocations.sum { |item| item.amount.to_f }
  end

  # Lo que quedo sin asignar a ninguna deuda. Negativo si se abono de mas.
  def unallocated_total
    amount.to_f - allocated_total
  end

  # ── Metadatos ────────────────────────────────────────────────────────────

  def origin_key
    recurring? ? :recurring : :manual
  end

  def uuid_short
    uuid.to_s.truncate(22)
  end

  # ── Formato ──────────────────────────────────────────────────────────────

  def format_currency(value)
    number_to_currency(value.to_f, unit: '$')
  end

  def format_signed(value)
    "#{value.to_f.negative? ? '−' : '+'}#{format_currency(value.to_f.abs)}"
  end

  private

  def month_range
    transaction_date.all_month
  end

  # Dias que dura el ciclo, o nil si no hay ciclo del que hablar.
  def cycle_span
    return nil if cycle_start.nil? || cycle_end.nil?

    span = (cycle_end - cycle_start).to_i
    span.positive? ? span : nil
  end

  def same_day_transactions(excluded_ids)
    transaction.user.transactions
               .where(category_id: transaction.category_id, transaction_date:)
               .where.not(id: [transaction.id, *excluded_ids])
               .order(amount: :desc)
               .limit(3)
               .to_a
  end

  # En tarjeta se muestra la deuda; en cualquier otra cuenta, el saldo tal cual.
  def balance_of(amount_available)
    return amount_available.to_f unless credit_card? && limit_amount.positive?

    limit_amount - amount_available.to_f
  end

  def percent_of_limit(debt)
    return 0.0 unless limit_amount.positive?

    ((debt.to_f / limit_amount) * 100).round(1)
  end
end
