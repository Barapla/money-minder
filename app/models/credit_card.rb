# frozen_string_literal: true

# == Schema Information
class CreditCard < ApplicationRecord
  include Utils::CreditCard::TemporaryConsciousness

  belongs_to :budget
  has_many :credit_card_cycles, dependent: :destroy
  # has_many :credit_card_histories, dependent: :destroy
  has_many :transactions, through: :budget

  after_create :set_initial_debt
  after_save :update_budget_amount, if: :saved_change_to_limit_amount?

  private

  def set_initial_debt
    return unless initial_debt.present? && initial_debt > 0

    # Crear ciclo inicial con la deuda usando tu sistema existente
    cycle = current_cycle # Usa el método de tu TemporaryConsciousness
    cycle.update(
      current_balance: initial_debt,
      statement_balance: initial_debt,
      purchases_made: initial_debt
    )
  end

  def update_budget_amount
    # Ejemplo: actualizar current_amount basado en crédito disponible
    available_credit = limit_amount - budget.debt_amount
    budget.update(current_amount: available_credit)
  end
end
