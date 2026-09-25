# frozen_string_literal: true

# Calcula el progreso de cada presupuesto activo del usuario (FEAT-038).
#
# Usa los mismos metodos del modelo que el index web (BudgetPresenter ->
# Budget#debt_amount / #limit_amount / #current_amount / #budget_percentage)
# para que la app movil muestre exactamente las mismas cifras que /budgets.
class BudgetProgressCalculator
  # Excluye fondos de ahorro y ahorro a plazo: son vehiculos de acumulacion, no
  # presupuestos de gasto. Su progreso se expone via SavingsSummaryCalculator.
  NON_BUDGET_TYPES = %w[savings_fund term_saving].freeze

  def initialize(user)
    @user = user
  end

  def call
    budgets.map { |budget| entry_for(budget) }
  end

  private

  attr_reader :user

  def budgets
    user.budgets.where(active: true)
        .joins(:budget_type)
        .where.not(catalogs: { code: NON_BUDGET_TYPES })
        .includes(:color, :budget_type, :credit_card)
  end

  # debt_amount y limit_amount son 0.0 para tipos sin linea de credito (efectivo,
  # debito); para esos, percentage_used queda en 0 y la referencia util es
  # available_amount + spent_this_month.
  def entry_for(budget)
    { budget_id: budget.id,
      category_name: budget.name,
      category_color: budget.color&.value,
      budget_type: budget.budget_type&.code,
      debt_amount: budget.debt_amount.to_f,
      limit_amount: budget.limit_amount.to_f,
      available_amount: budget.current_amount.to_f,
      spent_this_month: budget.spent_amount_this_month.to_f,
      percentage_used: budget.budget_percentage.to_f }
  end
end
