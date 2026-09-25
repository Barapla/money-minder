# frozen_string_literal: true

# Presenta el index de transacciones: el resumen del mes, los filtros y los
# movimientos agrupados por dia.
#
# El filtrado va contra la BD, no en el navegador como en el index de
# presupuestos: aqui la lista esta paginada, y filtrar solo la pagina visible
# mentiria sobre los totales y sobre los contadores de los chips.
class TransactionsIndexPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper
  include PaginationHelper

  PER_PAGE_OPTIONS = [10, 25, 50].freeze
  DEFAULT_PER_PAGE = 10
  # El diseño pedia un chip de "Intereses", que no es un tipo en esta app: un
  # abono de interes entra como income normal y nada lo distingue. Se usa
  # 'refund', que si existe en el catalogo transaction_types.
  TYPE_FILTERS = %w[expense income transfer refund].freeze
  SORTS = %w[date amount].freeze

  def initialize(user, params = {})
    @user = user
    @params = params
  end

  # ── Periodo ──────────────────────────────────────────────────────────────

  def month
    @month ||= parse_month
  end

  def date_range
    month.beginning_of_month..month.end_of_month
  end

  def month_label
    I18n.l(month, format: :month_year)
  end

  def previous_month
    month.prev_month
  end

  # No se navega al futuro: no hay movimientos que ver ahi.
  def next_month
    following = month.next_month
    following if following <= Date.current.beginning_of_month
  end

  def current_month?
    month == Date.current.beginning_of_month
  end

  # El mes en curso se muestra hasta hoy ("1–20 sep"), no hasta su ultimo dia.
  def range_end
    current_month? ? Date.current : month.end_of_month
  end

  def range_label
    "#{month.day}–#{range_end.day} #{I18n.l(month, format: '%b').downcase}"
  end

  # ── Totales del mes ──────────────────────────────────────────────────────

  def income_total
    @income_total ||= totals_by_type['income'].to_f
  end

  def expense_total
    @expense_total ||= totals_by_type['expense'].to_f
  end

  # Traspasos y pagos de tarjeta: el dinero sigue siendo tuyo o ya se conto como
  # gasto cuando se uso la tarjeta, asi que no entra ni en ingresos ni en gastos.
  def internal_total
    @internal_total ||= totals_by_type['transfer'].to_f
  end

  def net_total
    income_total - expense_total
  end

  def net_share
    return 0 unless income_total.positive?

    ((net_total / income_total) * 100).round
  end

  def income_count
    type_counts_hash['income'].to_i
  end

  def expense_count
    type_counts_hash['expense'].to_i
  end

  def expense_categories_count
    @expense_categories_count ||= month_scope.where(transaction_type: type_catalog('expense'))
                                             .distinct.count(:category_id)
  end

  # ── Filtros ──────────────────────────────────────────────────────────────

  def search_term
    @params[:q].presence
  end

  def selected_type
    code = @params[:type].presence
    code if TYPE_FILTERS.include?(code)
  end

  def selected_budget_id
    @params[:budget_id].presence
  end

  def selected_category_id
    @params[:category_id].presence
  end

  def sort
    SORTS.include?(@params[:sort]) ? @params[:sort] : 'date'
  end

  # [[codigo, cantidad]] para los chips. Cuenta sobre todo menos el propio filtro
  # de tipo, para que los chips sigan diciendo cuanto hay al otro lado.
  def type_counts
    TYPE_FILTERS.map { |code| [code, type_counts_hash[code].to_i] }
  end

  def total_count
    @total_count ||= type_counts_hash.values.sum
  end

  def budgets
    @budgets ||= user.budgets.order(:name).to_a
  end

  def categories
    @categories ||= Category.where(id: month_scope.select(:category_id)).order(:name).to_a
  end

  def filtered?
    search_term || selected_type || selected_budget_id || selected_category_id
  end

  # ── Lista ────────────────────────────────────────────────────────────────

  def any?
    filtered_count.positive?
  end

  def filtered_count
    @filtered_count ||= filtered_scope.count
  end

  # [[fecha, [transacciones]]] de la pagina actual, en el orden en que salen.
  def days
    @days ||= page_transactions.group_by(&:transaction_date)
  end

  def day_total(transactions)
    transactions.sum { |transaction| signed_amount(transaction) }
  end

  # Un movimiento que resta se muestra en negativo aunque en la BD el monto sea
  # positivo: la columna `amount` no guarda el signo, lo pone el tipo.
  def signed_amount(transaction)
    transaction.negative_transaction? ? -transaction.amount.to_f : transaction.amount.to_f
  end

  def format_signed(amount)
    "#{amount.negative? ? '−' : '+'}#{format_currency(amount.abs)}"
  end

  def format_currency(amount)
    number_to_currency(amount, unit: '$')
  end

  def today?(date)
    date == Date.current
  end

  def yesterday?(date)
    date == Date.current - 1
  end

  # Marca los dias en los que cae una quincena, con el mismo generador que usa el
  # calendario. Sin EmploymentInformation/PayrollProfile no marca nada.
  def payday?(date)
    payday_dates.include?(date)
  end

  # ── Paginacion ───────────────────────────────────────────────────────────

  def page
    @page ||= [@params[:page].to_i, 1].max
  end

  def per_page
    @per_page ||= PER_PAGE_OPTIONS.include?(@params[:per_page].to_i) ? @params[:per_page].to_i : DEFAULT_PER_PAGE
  end

  # Nombre propio: PaginationHelper#total_pages ya ocupa ese, y redefinirlo aqui
  # se llamaria a si mismo.
  def page_count
    @page_count ||= [total_pages(per_page, filtered_count), 1].max
  end

  def pages
    pagination_pages(page, page_count)
  end

  def first_page?
    page <= 1
  end

  def last_page?
    page >= page_count
  end

  def showing_label
    from = ((page - 1) * per_page) + 1
    "#{from}–#{[from + per_page - 1, filtered_count].min}"
  end

  private

  attr_reader :user

  def parse_month
    Date.parse("#{@params[:month]}-01").beginning_of_month
  rescue ArgumentError, TypeError
    Date.current.beginning_of_month
  end

  # Base del mes: cada movimiento una sola vez. Un traspaso crea un income espejo
  # con related_transaction_id apuntando al original (ver RelatedTransaction); sin
  # este filtro cada traspaso saldria dos veces y los totales se inflarian.
  def month_scope
    @month_scope ||= user.transactions
                         .where(transaction_date: date_range, related_transaction_id: nil)
  end

  def filtered_scope
    @filtered_scope ||= begin
      scope = scope_without_type
      scope = scope.where(transaction_type: type_catalog(selected_type)) if selected_type
      scope
    end
  end

  def scope_without_type
    scope = month_scope
    scope = scope.where(budget_id: selected_budget_id) if selected_budget_id
    scope = scope.where(category_id: selected_category_id) if selected_category_id
    scope = apply_search(scope) if search_term
    scope
  end

  # Busca en la descripcion y en el nombre de la categoria, como pide el diseño.
  def apply_search(scope)
    pattern = "%#{search_term.strip}%"
    scope.left_joins(:category)
         .where('transactions.description ILIKE :q OR categories.name ILIKE :q', q: pattern)
  end

  def page_transactions
    @page_transactions ||= filtered_scope
                           .includes(:category, :icon, :color, :transaction_type, :budget, :related_budget)
                           .order(*order_clause)
                           .offset((page - 1) * per_page)
                           .limit(per_page)
                           .to_a
  end

  def order_clause
    return [{ amount: :desc }, { transaction_date: :desc }] if sort == 'amount'

    [{ transaction_date: :desc }, { created_at: :desc }]
  end

  def totals_by_type
    @totals_by_type ||= month_scope.joins(:transaction_type)
                                   .group('catalogs.code')
                                   .sum(:amount)
  end

  def type_counts_hash
    @type_counts_hash ||= scope_without_type.joins(:transaction_type)
                                            .group('catalogs.code')
                                            .count
  end

  def type_catalog(code)
    @type_catalogs ||= {}
    @type_catalogs[code] ||= Catalog.by_group_and_code('transaction_types', code)
  end

  def payday_dates
    @payday_dates ||= PayrollServices::ReminderGenerator
                      .new(user)
                      .generate(from_date: month.beginning_of_month, to_date: month.end_of_month)
                      .map(&:date).to_set
  rescue StandardError
    Set.new
  end
end
