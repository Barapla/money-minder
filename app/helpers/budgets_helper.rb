# frozen_string_literal: true

# BudgetsHelper
module BudgetsHelper
  # Los unicos 3 tipos con seccion propia pedida por el ticket (FEAT-032 AC1-AC3);
  # cualquier otro budget_type (cash, term_saving) cae al fallback de budget_type.value
  # para no perder esos budgets de la vista sin necesitar una traduccion dedicada.
  SECTION_TITLE_I18N_KEYS = {
    'credit_card' => 'credit_cards',
    'debit_card' => 'debit_cards',
    'savings_fund' => 'savings_funds'
  }.freeze

  def budget_section_title(code, budgets)
    key = SECTION_TITLE_I18N_KEYS[code]
    key ? t("budgets.index.sections.#{key}") : budgets.first&.budget_type&.value
  end

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
        { value: budget_presenter.debt_amount,
          div_color: budget.budget_color },
        { value: budget_presenter.limit_amount },
        { value: budget_presenter.current_amount,
          div_color: budget.budget_color },
        { type: 'progress_bar', value: budget_presenter.budget_percentage,
          div_color: budget.budget_color },
        { type: 'status', value: budget.budget_status, color: budget.budget_color },
        {
          type: 'actions',
          actions: [
            { name: 'Ver', icon: 'eye', path: budget_path(budget),
              options: { class: 'hover:text-white', data: { turbo: false } } },
            { name: 'Editar', icon: 'edit', path: edit_budget_path(budget),
              options: { class: 'hover:text-purple-400', data: { turbo: false } } },
            {
              name: 'Eliminar', icon: 'trash', path: budget_path(budget),
              options: {
                class: 'hover:text-red-400',
                data: { turbo_method: :delete,
                        turbo_confirm: '¿Estás seguro de que quieres eliminar este presupuesto?' }
              }
            }
          ]
        }
      ]
    end
  end
end
