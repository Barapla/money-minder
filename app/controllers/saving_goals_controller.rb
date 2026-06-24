# frozen_string_literal: true

# SavingGoalsController maneja el CRUD de metas de ahorro del usuario autenticado.
class SavingGoalsController < ApplicationController
  AuthorizationError = Class.new(StandardError)

  before_action :authenticate_user!
  before_action :set_saving_goal, only: %i[edit update destroy]

  def index
    @saving_goals = current_user.saving_goals.recent_first
    @active_goals_by_priority = current_user.saving_goals.where(status: :active).order(:priority_order)
    @allocations = SavingGoalServices::PriorityAllocator.new(current_user).allocate
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
    new_order = parse_order_params
    return render json: { error: 'Parámetros inválidos' }, status: :unprocessable_entity if new_order.nil?

    apply_reorder(new_order)
    render json: { success: true }
  rescue AuthorizationError => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::ActiveRecordError
    render json: { error: 'Error al guardar el orden' }, status: :unprocessable_entity
  end

  private

  def apply_reorder(new_order)
    SavingGoal.transaction do
      verify_goal_ownership!(new_order)
      current_user.saving_goals.where(status: :active).update_all('priority_order = priority_order + 10000')
      assign_final_priorities(new_order)
    end
  end

  def verify_goal_ownership!(new_order)
    user_active_ids = current_user.saving_goals.where(status: :active).lock.pluck(:id).sort
    return if new_order.sort == user_active_ids

    raise AuthorizationError, 'El orden enviado no coincide con tus metas activas'
  end

  def assign_final_priorities(new_order)
    return if new_order.empty?

    when_placeholders = (['WHEN ? THEN ?'] * new_order.size).join(' ')
    binds = new_order.each_with_index.flat_map { |id, i| [id, i + 1] }
    current_user.saving_goals.where(id: new_order)
                .update_all(["priority_order = CASE id #{when_placeholders} END", *binds])
  end

  def parse_order_params
    order = params[:order]
    return nil unless order.is_a?(Array) && order.any?
    return nil unless order.all? { |v| v.to_s.match?(/\A\d+\z/) }

    order.map(&:to_i)
  end

  def set_saving_goal
    @saving_goal = current_user.saving_goals.find(params[:id])
  end

  def saving_goal_params
    params.require(:saving_goal).permit(:name, :target_amount, :deadline, :status)
  end
end
