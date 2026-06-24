# frozen_string_literal: true

# Dashboard financiero: agrega saldos, tarjetas y alertas del usuario.
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @presenter = DashboardPresenter.new(current_user)
  end

  def saving_goals_recalculate
    presenter = DashboardPresenter.new(current_user)
    goals = presenter.prioritized_saving_goals.map { |item| serialize_goal(item) }
    render json: { goals: goals }
  rescue StandardError
    render json: { error: 'No se pudo calcular las metas de ahorro.' }, status: :unprocessable_entity
  end

  private

  def serialize_goal(item)
    goal = item[:saving_goal]
    { id: goal.id,
      allocated_amount: item[:allocated_amount],
      allocated_formatted: item[:allocated_formatted],
      percentage: item[:progress_percentage] }
  end
end
