# frozen_string_literal: true

# BudgetsHelper
module BudgetsHelper
  def headers_table_index
    [
      { name: 'Tipo de Presupuesto', size: 'min-w-[180px]' },
      { name: 'Monto Actual', size: 'min-w-[120px]' },
      { name: 'Límite', size: 'min-w-[120px]' },
      { name: 'Disponible', size: 'min-w-[120px]' },
      { name: 'Progreso', size: 'min-w-[120px]' },
      { name: 'Estado', size: 'min-w-[120px]' }
    ]
  end

  def budget_type_options
    [
      ['🏠 Gastos Fijos', 'gastos_fijos'],
      ['🛒 Gastos Variables', 'gastos_variables'],
      ['💰 Ahorros', 'ahorros'],
      ['📈 Inversiones', 'inversiones'],
      ['🎉 Entretenimiento', 'entretenimiento']
    ]
  end
end
