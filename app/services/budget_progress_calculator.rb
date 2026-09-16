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

  # Excluye fondos de ahorro y ahorro a plazo: son vehiculos de acumulacion, no
  # presupuestos de gasto, y su saldo/aportes producen porcentajes sin sentido
  # (ej. una transferencia al fondo se contaba como "gasto" contra su saldo).
  # Su progreso real ya se expone por separado via SavingsSummaryCalculator.
  NON_BUDGET_TYPES = %w[savings_fund term_saving].freeze

  def budgets
    user.budgets.where(active: true)
        .joins(:budget_type)
        .where.not(catalogs: { code: NON_BUDGET_TYPES })
        .includes(:color, :budget_type)
  end

  def entry_for(budget)
    spent = budget.spent_amount_this_month.to_f
    budgeted = budget.current_amount.to_f
    percentage = budgeted.positive? ? ((spent / budgeted) * 100).round(2) : 0.0

    { budget_id: budget.id,
      category_name: budget.name,
      category_color: budget.color&.value,
      budget_type: budget.budget_type&.code,
      budgeted_amount: budgeted,
      spent_amount: spent,
      remaining_amount: (budgeted - spent).round(2),
      percentage_used: percentage }
  end
end
