# frozen_string_literal: true

# BudgetsController handles the display of budgets.
class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[show edit update destroy]

  # GET /budgets
  # GET /budgets.json
  def index
    @budgets = Budget.all
  end

  def show
    @budget_presenter = BudgetPresenter.new(@budget)
  end

  def new
    @budget = Budget.new
  end

  def create
    @budget = Budget.new(budget_params)
    if @budget.save
      redirect_to budgets_path, notice: 'Presupuesto creado exitosamente.'
    else
      flash.now[:alert] = 'Error al crear el presupuesto. Por favor, revisa los datos ingresados.'
      render :new
    end
  end

  def edit
  end

  def update
    if @budget.update(budget_params)
      redirect_to budgets_path, notice: 'Presupuesto actualizado exitosamente.'
    else
      flash.now[:alert] = 'Error al actualizar el presupuesto. Por favor, revisa los datos ingresados.'
      render :edit
    end
  end

  def destroy
  end

  private

  def budget_params
    params.require(:budget).permit(:name, :budget_type_id, :current_amount, :limit_amount, :debt_amount,
                                   :payday, :cutting_day, :icon_id, :color_id, :user_id)
  end

  def set_budget
    @budget = Budget.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: 'Presupuesto no encontrado.'
  end
end
