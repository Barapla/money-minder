# frozen_string_literal: true

# Calcula el progreso de cada presupuesto activo contra el gasto del mes actual (FEAT-038).
class BudgetProgressCalculator
  def initialize(user)
    @user = user
  end

  def call
    budgets.map { |budget| entry_for(budget) }
  end

  private

  attr_reader :user

  def budgets
    user.budgets.where(active: true).includes(:color)
  end

  def entry_for(budget)
    spent = budget.spent_amount_this_month.to_f
    budgeted = budget.current_amount.to_f
    percentage = budgeted.positive? ? ((spent / budgeted) * 100).round(2) : 0.0

    { budget_id: budget.id,
      category_name: budget.name,
      category_color: budget.color&.value,
      budgeted_amount: budgeted,
      spent_amount: spent,
      remaining_amount: (budgeted - spent).round(2),
      percentage_used: percentage }
  end
end
