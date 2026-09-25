# frozen_string_literal: true

module Api
  module V1
    # GET  /api/v1/saving_goals  — activas por prioridad, luego el resto (mas recientes primero)
    # POST /api/v1/saving_goals  { saving_goal: { name, target_amount, deadline } }
    class SavingGoalsController < ApplicationController
      include Api::JwtAuthenticatable

      def index
        goals = saving_goals.active.by_priority + saving_goals.where.not(status: :active).recent_first
        render json: { records: goals.map { |goal| serialize(goal) } }, status: :ok
      end

      def create
        goal = saving_goals.build(params.require(:saving_goal).permit(:name, :target_amount, :deadline))
        return render_validation_errors(goal) unless goal.save

        render json: { record: serialize(goal) }, status: :created
      end

      private

      def saving_goals
        current_api_user.saving_goals
      end

      def serialize(goal)
        SavingGoalSerializer.new(goal, allocated_amount: allocations.fetch(goal.id, 0)).as_json
      end

      def allocations
        @allocations ||= SavingGoalServices::PriorityAllocator.new(current_api_user).allocate
      end
    end
  end
end
