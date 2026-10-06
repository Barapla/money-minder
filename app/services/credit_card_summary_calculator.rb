# frozen_string_literal: true

# Calcula el resumen de tarjetas de credito activas: saldo, limite y proximas fechas (FEAT-038).
class CreditCardSummaryCalculator
  NO_CUTTING_DATE = Date.new(9999, 12, 31)

  def initialize(user)
    @user = user
  end

  def call
    credit_card_budgets.map { |budget| entry_for(budget) }
                       .sort_by { |entry| entry[:next_cutting_date] || NO_CUTTING_DATE }
  end

  private

  attr_reader :user

  def credit_card_budgets
    user.budgets
        .joins(:credit_card)
        .where(credit_cards: { active: true })
        .includes(:credit_card)
  end

  def entry_for(budget)
    card = budget.credit_card

    { card_id: card.id,
      card_name: budget.name,
      current_balance: card.calculated_balance,
      credit_limit: card.limit_amount.to_f,
      available_credit: card.available_credit.to_f,
      next_cutting_date: card.next_cutting_date,
      next_payment_date: card.next_payment_due_date }
  end
end
