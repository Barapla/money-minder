# frozen_string_literal: true

# Meta de ahorro definida por el usuario con progreso calculado en tiempo real.
# El campo priority_order determina el orden en el dashboard y la secuencia de
# asignación automática de saldo disponible. Se asigna automáticamente al crear
# y se renumera al eliminar para evitar gaps.
class SavingGoal < ApplicationRecord
  belongs_to :user

  enum :status, { active: 0, paused: 1, achieved: 2, cancelled: 3 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :priority_order, presence: true, uniqueness: { scope: :user_id },
                             numericality: { only_integer: true, greater_than: 0 }
  validates :deadline,
            comparison: { greater_than_or_equal_to: -> { Date.today } },
            allow_nil: true,
            on: :create

  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_status, ->(s) { where(status: s) }
  scope :by_priority, -> { order(:priority_order) }

  before_validation :assign_last_priority, on: :create
  after_destroy :renumber_priorities

  private

  def assign_last_priority
    return unless priority_order.nil?
    return unless user

    self.priority_order = (user.saving_goals.maximum(:priority_order) || 0) + 1
  end

  def renumber_priorities
    goal_ids = user.saving_goals.order(:priority_order).pluck(:id)
    return if goal_ids.empty?

    when_placeholders = (['WHEN ? THEN ?'] * goal_ids.size).join(' ')
    binds = goal_ids.each_with_index.flat_map { |id, i| [id, i + 1] }
    user.saving_goals.where(id: goal_ids)
        .update_all(["priority_order = CASE id #{when_placeholders} END", *binds])
  end
end
