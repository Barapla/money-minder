# frozen_string_literal: true

# == Schema Information
class CreditCard < ApplicationRecord
  include Utils::CreditCard::TemporaryConsciousness
  include Utils::CreditCard::CycleAssignment
  include FinancialProductAssociable

  belongs_to :budget
  has_many :credit_card_cycles, dependent: :destroy
  # has_many :credit_card_histories, dependent: :destroy
  has_many :transactions, through: :budget

  after_create :set_initial_debt
  after_update :update_first_cycle_debt, if: :saved_change_to_initial_debt?
  after_save :update_budget_amount, if: :saved_change_to_limit_amount?

  def update_budget_amount
    # Ejemplo: actualizar current_amount basado en crédito disponible
    available_credit = limit_amount - budget.debt_amount
    budget.update(current_amount: available_credit)
  end

  private

  def update_first_cycle_debt
    first_cycle = credit_card_cycles.order(cutting_date: :asc).first
    return unless first_cycle

    first_cycle.update(historical_balance: initial_debt)
  end

  def set_initial_debt
    return unless initial_debt.present? && initial_debt.positive?

    cycle = current_cycle
    cycle.update(purchases: initial_debt)
  end
end
