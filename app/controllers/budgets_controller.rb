# frozen_string_literal: true

# BudgetsController handles the display of budgets.
class BudgetsController < ApplicationController
  def index
    @budgets = Budget.all
  end

  def show
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
  end

  def destroy
  end

  private

  def budget_params
    params.require(:budget).permit(:name, :budget_type_id, :current_amount, :limit_amount, :icon_id, :color_id)
  end
end
