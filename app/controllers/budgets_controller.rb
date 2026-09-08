# frozen_string_literal: true

# BudgetsController handles the display of budgets.
class BudgetsController < ApplicationController
  include PaginationHelper
  include BudgetsHelper
  before_action :authenticate_user!
  before_action :set_budget, only: %i[show show_transactions edit update destroy]

  # Tipo de instrumento (Registry) al que corresponde cada budget_type.code (FEAT-027).
  REGISTRY_TYPE_BY_BUDGET_CODE = {
    'cash' => FinancialCatalogServices::Registry::CASH,
    'debit_card' => FinancialCatalogServices::Registry::DEBIT,
    'credit_card' => FinancialCatalogServices::Registry::CREDIT,
    'savings_fund' => FinancialCatalogServices::Registry::SAVINGS,
    'term_saving' => FinancialCatalogServices::Registry::TERM_SAVING
  }.freeze

  # GET /budgets
  # GET /budgets.json
  def index
    budgets = Budget.where(user: current_user)
    # budgets = Budget.where(budget_type: Catalog.by_group_and_code('budget_types', 'credit_card'),
    #                        user: current_user)
    @total_collections = budgets.count
    @budgets = budgets.limit(10)
  end

  def budgets_table
    id = params[:id]
    # query = params[:query]
    current_page = params[:page]
    per_page = params[:perPage].to_i
    # select_filters = params[:select_filters] || []
    # checkbox_filters = params[:checkbox_filters] || {}

    # budgets = Budget.where(budget_type: Catalog.by_group_and_code('budget_types', 'credit_card'),
    #                        user: current_user).order(:id)

    budgets = Budget.where(user: current_user)

    # tickets = apply_select_filters(tickets, select_filters)
    # users = apply_checkbox_filters(users, checkbox_filters)
    # users = apply_query(users, query) if query.present?

    total_budgets = budgets.count

    budgets = budgets.offset(
      (current_page.to_i - 1) * per_page.to_i
    ).limit(per_page)

    total_pages = total_pages(per_page, total_budgets)
    pagination_pages = pagination_pages(current_page, total_pages)

    @budgets = values_table_format(budgets)
    stream = turbo_stream.update("table-#{id}", partial: 'components/table/main/table',
                                                locals: { headers: headers_table_index.push({ name: 'Acciones', size: 'min-w-[120px]' }), values: @budgets, id:,
                                                          per_page:, current_page:, total_collections: total_budgets,
                                                          total_pages:, pagination_pages: })
    respond_to do |format|
      format.turbo_stream { render turbo_stream: stream }
    end
  end

  def show
    @budget_presenter = BudgetPresenter.new(@budget)
  end

  def show_transactions
    streams = turbo_stream_for_budget_transactions
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: streams
      end
    end
  end

  # Paso 1 del wizard de creacion (FEAT-027): eleccion del tipo de presupuesto.
  def new
    session[:budget_wizard] = {}
    @budget_types = Catalog.by_group('budget_types')
  end

  # Paso 2 del wizard: instituciones con productos del tipo elegido en el paso 1.
  # Si el tipo no tiene productos en el catalogo (ej. cash), se salta directo al paso 4.
  def wizard_step2
    @budget_type = resolve_wizard_type(wizard_type_param)
    return redirect_to_invalid_step unless @budget_type

    session[:budget_wizard] = { 'type' => @budget_type.code }
    @institutions = registry_for(@budget_type).map(&:institution).uniq.sort
    redirect_to wizard_step4_budgets_path if @institutions.empty?
  end

  # Paso 3 del wizard: productos de la institucion elegida en el paso 2.
  def wizard_step3
    return unless require_wizard_budget_type!

    institution = params[:institution].presence || wizard_state['institution']
    return redirect_to_missing_institution unless institution

    session[:budget_wizard]['institution'] = institution
    @institution = institution
    @products = registry_for(@budget_type).by_institution(institution).to_a
  end

  # Paso 4 del wizard: formulario de detalles, con producto (si se eligio uno) precargado.
  def wizard_step4
    return unless require_wizard_budget_type!

    session[:budget_wizard]['product_id'] = params[:product_id] if params.key?(:product_id)
    @back_path = wizard_step4_back_path
    @budget = build_wizard_budget(@budget_type, session[:budget_wizard]['product_id'])
  end

  def create
    @budget = current_user.budgets.new(budget_params)
    if @budget.save
      session.delete(:budget_wizard)
      redirect_to @budget, notice: t('budgets.create.success')
    else
      flash.now[:alert] = t('budgets.create.error')
      @budget_type = @budget.budget_type
      @back_path = wizard_step4_back_path
      render :wizard_step4
    end
  end

  def edit; end

  def update
    if @budget.update(budget_params)
      redirect_to @budget, notice: t('budgets.update.success')
    else
      flash.now[:alert] = t('budgets.update.error')
      render :edit
    end
  end

  def change_budget_type
    budget_type = Catalog.find(params[:budget][:budget_type_id])
    stream = turbo_stream_for_budget_type(budget_type)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: stream
      end
    end
  end

  def destroy
    @budget.destroy
    redirect_to budgets_path, notice: t('budgets.destroy.success')
  end

  private

  def budget_params
    params.require(:budget).permit(
      :name, :budget_type_id, :current_amount, :icon_id, :color_id, :financial_product_id,
      credit_card_attributes: %i[initial_debt limit_amount cutting_day payment_due_days financial_product_id],
      savings_fund_attributes: %i[goal_amount target_date monthly_contribution interest_rate compound_frequency_id
                                  account_type_id minimum_balance max_balance financial_product_id],
      term_savings_attributes: %i[id name term_days rate_locked started_at principal_amount financial_product_id]
    )
  end

  def set_budget
    @budget = current_user.budgets.find(params[:id])
  end

  def wizard_state
    session[:budget_wizard] ||= {}
  end

  def current_wizard_budget_type
    resolve_wizard_type(wizard_state['type'])
  end

  def resolve_wizard_type(type_code)
    type_code && Catalog.by_group_and_code('budget_types', type_code)
  end

  def wizard_type_param
    params[:type].presence || wizard_state['type']
  end

  def require_wizard_budget_type!
    @budget_type = current_wizard_budget_type
    return true if @budget_type

    redirect_to_invalid_step
    false
  end

  def redirect_to_invalid_step
    redirect_to new_budget_path, alert: t('budgets.wizard.errors.invalid_step')
  end

  def redirect_to_missing_institution
    redirect_to wizard_step2_budgets_path, alert: t('budgets.wizard.errors.missing_institution')
  end

  def registry_for(budget_type)
    FinancialCatalogServices::Registry.by_type(REGISTRY_TYPE_BY_BUDGET_CODE.fetch(budget_type.code))
  end

  def wizard_step4_back_path
    return wizard_step3_budgets_path if wizard_state['institution'].present?
    return wizard_step2_budgets_path if registry_for(@budget_type).map(&:institution).any?

    new_budget_path
  end

  # Precarga el producto elegido en el paso 3 en el instrumento correcto: columna propia
  # de Budget para debit_card, o atributo del modelo anidado para los demas tipos.
  def build_wizard_budget(budget_type, product_id)
    budget = current_user.budgets.new(budget_type:)
    return budget if product_id.blank?

    case budget_type.code
    when 'debit_card' then budget.financial_product_id = product_id
    when 'credit_card' then budget.credit_card.financial_product_id = product_id
    when 'savings_fund' then budget.savings_fund.financial_product_id = product_id
    when 'term_saving' then budget.term_savings.first.financial_product_id = product_id
    end

    budget
  end

  def turbo_stream_for_budget_type(budget_type)
    [
      turbo_stream.update(
        'budget_type_frame',
        partial: "budgets/forms/#{budget_type.code}/form", locals: { budget: Budget.new(budget_type:) }
      ),
      turbo_stream.update(
        'preview_frame',
        partial: "budgets/forms/#{budget_type.code}/preview", locals: { budget: Budget.new(budget_type:) }
      )
    ]
  end

  def turbo_stream_for_budget_transactions
    [
      turbo_stream.update(
        'recent_transactions',
        partial: 'budgets/shows/shared/recent_transactions/transactions', locals: { limit: nil }
      ),
      turbo_stream.remove('button_show_transactions')
    ]
  end
end
