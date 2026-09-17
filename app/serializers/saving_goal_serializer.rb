# frozen_string_literal: true

# Serializa una meta de ahorro para la API movil. `allocated_amount` es la parte
# del saldo disponible asignada a la meta por prioridad (PriorityAllocator),
# el mismo criterio que la vista web de metas.
class SavingGoalSerializer
  def initialize(goal, allocated_amount:)
    @goal = goal
    @allocated_amount = allocated_amount.to_f
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength -- lectura plana de campos, sin logica
  def as_json(*)
    {
      id: goal.id,
      name: goal.name,
      target_amount: goal.target_amount.to_f,
      allocated_amount:,
      progress_percentage: progress_percentage,
      deadline: goal.deadline,
      days_remaining: goal.deadline && (goal.deadline - Date.current).to_i,
      status: goal.status,
      priority_order: goal.priority_order
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  attr_reader :goal, :allocated_amount

  def progress_percentage
    return 0.0 unless goal.target_amount.positive?

    [(allocated_amount / goal.target_amount.to_f * 100).round(2), 100.0].min
  end
end
