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

  # Proxima fecha de corte del ciclo vigente, o nil si no hay dia de corte configurado.
  def next_cutting_date
    return nil if cutting_day.blank?

    today = Date.current
    day = cutting_day.to_i
    return Date.new(today.year, today.month, day) if today.day < day

    clamped_date(today >> 1, day)
  end

  # Fecha limite de pago del ciclo vigente: se calcula desde el corte ya cerrado
  # (aunque haya sido este mismo mes). Si ese pago ya vencio, usa el proximo corte.
  def next_payment_due_date
    return nil if cutting_day.blank? || payment_due_days.blank?

    days = payment_due_days.to_i
    candidate = previous_cutting_date + days.days
    candidate >= Date.current ? candidate : next_cutting_date + days.days
  end

  def calculated_balance
    current_debt.to_f
  end

  private

  def previous_cutting_date
    today = Date.current
    day = cutting_day.to_i
    return clamped_date(today, day) if today.day >= day

    clamped_date(today << 1, day)
  end

  # Limita el dia al ultimo del mes de base_date para evitar fechas invalidas (ej: 31 en febrero).
  def clamped_date(base_date, day)
    Date.new(base_date.year, base_date.month, [day, base_date.end_of_month.day].min)
  end

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
