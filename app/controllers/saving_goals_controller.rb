# frozen_string_literal: true

# SavingGoalsController maneja el CRUD de metas de ahorro del usuario autenticado.
class SavingGoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_saving_goal, only: %i[edit update destroy]

  def index
    @saving_goals = current_user.saving_goals.recent_first
    @calculator = SavingGoalServices::ProgressCalculator.new(current_user)
  end

  def new
    @saving_goal = SavingGoal.new
  end

  def create
    @saving_goal = current_user.saving_goals.build(saving_goal_params)

    if @saving_goal.save
      redirect_to saving_goals_path, notice: 'Meta de ahorro creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @saving_goal.update(saving_goal_params)
      redirect_to saving_goals_path, notice: 'Meta de ahorro actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @saving_goal.destroy
    redirect_to saving_goals_path, notice: 'Meta de ahorro eliminada exitosamente.'
  end

  def reorder
    new_order = (params[:order] || []).map(&:to_i)
    apply_reorder(new_order)
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def apply_reorder(new_order)
    SavingGoal.transaction do
      user_goal_ids = current_user.saving_goals.pluck(:id)
      raise ActiveRecord::RecordNotFound, 'Meta de ahorro no encontrada' unless (new_order - user_goal_ids).empty?

      # Fase 1: desplazar a valores temporales para evitar conflictos transitorios en el índice único
      current_user.saving_goals.update_all('priority_order = priority_order + 10000')
      # Fase 2: asignar el nuevo orden final
      new_order.each_with_index { |id, i| current_user.saving_goals.find(id).update_column(:priority_order, i + 1) }
    end
  end

  def set_saving_goal
    @saving_goal = current_user.saving_goals.find(params[:id])
  end

  def saving_goal_params
    params.require(:saving_goal).permit(:name, :target_amount, :deadline, :status)
  end
end
