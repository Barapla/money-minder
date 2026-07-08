# frozen_string_literal: true

# Beneficio asociado a un producto financiero (rendimiento, cashback, puntos, descuento).
class FinancialProductBenefit < ApplicationRecord
  belongs_to :financial_product

  enum :benefit_type, { annual_yield: 0, cashback: 1, points: 2, discount: 3 }
  # prefix evita conflicto de metodos con el enum benefit_type que tambien tiene :points
  enum :unit, { percentage: 0, points: 1, fixed_amount: 2 }, prefix: :unit

  validates :benefit_type, :base_value, :unit, presence: true
  validates :base_value, numericality: { greater_than: 0 }
  validates :reduced_value, numericality: { greater_than: 0 }, allow_nil: true
  validates :amount_cap, numericality: { greater_than: 0 }, allow_nil: true

  validate :percentage_values_in_range, if: :unit_percentage?

  scope :active, -> { where(active: true) }

  private

  def percentage_values_in_range
    errors.add(:base_value, :out_of_range) if base_value && (base_value.negative? || base_value > 100)
    errors.add(:reduced_value, :out_of_range) if reduced_value && (reduced_value.negative? || reduced_value > 100)
  end
end
