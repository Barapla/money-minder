# frozen_string_literal: true

# Meta de ahorro definida por el usuario con progreso calculado en tiempo real.
class SavingGoal < ApplicationRecord
  belongs_to :user

  enum :status, { active: 0, paused: 1, achieved: 2, cancelled: 3 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :deadline,
            comparison: { greater_than_or_equal_to: -> { Date.today } },
            allow_nil: true,
            on: :create

  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_status, ->(s) { where(status: s) }
end
