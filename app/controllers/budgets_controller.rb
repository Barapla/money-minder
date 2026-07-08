# frozen_string_literal: true

# BudgetsController handles the display of budgets.
class BudgetsController < ApplicationController
  include PaginationHelper
  include BudgetsHelper
  before_action :authenticate_user!
  before_action :set_budget, only: %i[show show_transactions edit update destroy]

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

  def new
    @budget = Budget.new
  end

  def create
    @budget = current_user.budgets.new(budget_params)
    if @budget.save
      redirect_to @budget, notice: t('budgets.create.success')
    else
      flash.now[:alert] = t('budgets.create.error')
      render :new
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
      :name, :budget_type_id, :current_amount, :icon_id, :color_id,
      credit_card_attributes: %i[initial_debt limit_amount cutting_day payment_due_days],
      savings_fund_attributes: %i[goal_amount target_date monthly_contribution interest_rate compound_frequency_id
                                  account_type_id minimum_balance max_balance]
    )
  end

  def set_budget
    @budget = current_user.budgets.find(params[:id])
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
