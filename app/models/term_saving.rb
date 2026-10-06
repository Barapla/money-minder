# frozen_string_literal: true

# Ahorro a plazo fijo que bloquea capital por un periodo definido con tasa de
# rendimiento fija (ej. Ahorro Congelado Nu 7/28/90/180 dias). El dinero bloqueado
# no cuenta como disponible para metas de ahorro mientras este activo y no haya
# vencido (ver LiquidityServices::Calculator, FEAT-024).
class TermSaving < ApplicationRecord
  include FinancialProductAssociable

  belongs_to :budget

  enum :status, { active: 0, matured: 1, withdrawn: 2 }

  validates :term_days, :rate_locked, :started_at, :principal_amount, presence: true
  validates :term_days, numericality: { only_integer: true, greater_than: 0 }
  validates :rate_locked, numericality: { greater_than_or_equal_to: 0 }
  validates :principal_amount, numericality: { greater_than: 0 }
  validate :rate_locked_immutable, on: :update

  before_validation :calculate_matures_at
  before_validation :sync_name_to_budget

  def mature!
    update!(status: :matured) if matures_at && matures_at <= Date.current
  end

  private

  def calculate_matures_at
    return unless started_at && term_days

    self.matures_at = started_at + term_days
  end

  def rate_locked_immutable
    errors.add(:rate_locked, :immutable) if rate_locked_changed?
  end

  # El wizard (FEAT-027) ya no pide un nombre de presupuesto aparte: se reusa el
  # nombre del ahorro (manual u autogenerado por FinancialProductAssociable) para
  # el Budget contenedor, que tambien exige `name` presente.
  def sync_name_to_budget
    return unless budget && name.present? && budget.name.blank?

    budget.name = name
  end

  def financial_product_name_prefix
    'Ahorro'
  end
end
