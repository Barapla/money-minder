# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BudgetProgressCalculator do
  let(:user) { create(:user) }

  subject(:calculator) { described_class.new(user) }

  it 'retorna el progreso de cada presupuesto activo del usuario' do
    budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 300, type_code: 'expense')

    result = calculator.call

    expect(result).to eq(
      [{ budget_id: budget.id, category_name: budget.name, category_color: 'Purple',
         budgeted_amount: 700.0, spent_amount: 300.0, remaining_amount: 400.0, percentage_used: 42.86 }]
    )
  end

  it 'excluye presupuestos inactivos' do
    budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
    budget.update!(active: false)

    expect(calculator.call).to eq([])
  end

  it 'retorna percentage_used 0.0 cuando budgeted_amount es cero' do
    make_budget(user:, type_code: 'cash', amount: 0, personal: true)

    result = calculator.call

    expect(result.first[:percentage_used]).to eq(0.0)
  end

  it 'retorna array vacio cuando el usuario no tiene presupuestos' do
    expect(calculator.call).to eq([])
  end
end
