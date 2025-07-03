# frozen_string_literal: true

# BudgetsHelper
module BudgetsHelper
  def headers_table_index
    [
      { name: 'Tipo de Presupuesto', size: 'min-w-[180px]' },
      { name: 'Monto Gastado', size: 'min-w-[120px]' },
      { name: 'Límite', size: 'min-w-[120px]' },
      { name: 'Disponible', size: 'min-w-[120px]' },
      { name: 'Progreso', size: 'min-w-[120px]' },
      { name: 'Estado', size: 'min-w-[120px]' }
    ]
  end

  def values_table_format(budgets)
    budgets.map do |budget|
      budget_presenter = BudgetPresenter.new(budget)
      [
        { type: 'icon', icon: budget_presenter.icon, color: budget_presenter.color,
          main_text: budget_presenter.name, sub_text: budget_presenter.budget_type },
        { value: budget_presenter.current_amount,
          div_color: budget.budget_color },
        { value: budget_presenter.limit_amount },
        { value: budget_presenter.available_amount,
          div_color: budget.budget_color },
        { type: 'progress_bar', value: budget.budget_percentage,
          div_color: budget.budget_color },
        { type: 'status', value: budget.budget_status, color: budget.budget_color },
        {
          type: 'actions',
          actions: [
            { name: 'Ver', icon: 'eye', path: budget_path(budget) },
            { name: 'Editar', icon: 'edit', path: edit_budget_path(budget) },
            { name: 'Eliminar', icon: 'trash', path: budget_path(budget), method: :delete,
              data: { confirm: '¿Estás seguro de que deseas eliminar este presupuesto?' } }
          ]
        }
      ]
    end
  end
end
