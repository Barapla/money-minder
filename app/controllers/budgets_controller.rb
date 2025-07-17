# frozen_string_literal: true

# BudgetsController handles the display of budgets.
class BudgetsController < ApplicationController
  include BudgetsHelper
  before_action :authenticate_user!
  before_action :set_budget, only: %i[show show_transactions edit update destroy]

  # GET /budgets
  # GET /budgets.json
  def index
    # @budgets = Budget.where(budget_type: Catalog.by_group_and_code('budget_types', 'credit_card'))
    @budgets = Budget.where(user: current_user)
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
    @budget = Budget.new(budget_params)
    @budget.current_amount = @budget.credit_card.limit_amount - @budget.credit_card.debt_amount
    if @budget.save
      redirect_to budgets_path, notice: 'Presupuesto creado exitosamente.'
    else
      flash.now[:alert] = 'Error al crear el presupuesto. Por favor, revisa los datos ingresados.'
      render :new
    end
  end

  def edit; end

  def update
    if @budget.update(budget_params)
      redirect_to budgets_path, notice: 'Presupuesto actualizado exitosamente.'
    else
      flash.now[:alert] = 'Error al actualizar el presupuesto. Por favor, revisa los datos ingresados.'
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
    @budget = Budget.find(params[:id])
    @budget.destroy
    redirect_to budgets_path, notice: 'Presupuesto eliminado exitosamente'
  end

  private

  def budget_params
    params.require(:budget).permit(
      :name, :budget_type_id, :current_amount, :icon_id, :color_id, :user_id,
      credit_card_attributes: %i[limit_amount debt_amount payday cutting_day],
      savings_fund_attributes: %i[goal_amount target_date monthly_contribution interest_rate compound_frequency_id
                                  account_type_id minimum_balance max_balance]
    )
  end

  def set_budget
    @budget = Budget.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: 'Presupuesto no encontrado.'
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
