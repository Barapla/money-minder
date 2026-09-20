# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BudgetProgressCalculator do
  let(:user) { create(:user) }

  subject(:calculator) { described_class.new(user) }

  it 'usa deuda/limite de la tarjeta, igual que el index web' do
    card = make_credit_card(user:, limit_amount: 30_000, cutting_day: 15)
    budget = card.budget.reload

    result = calculator.call.find { |entry| entry[:budget_id] == budget.id }

    expect(result[:budget_type]).to eq('credit_card')
    expect(result[:limit_amount]).to eq(30_000.0)
    expect(result[:debt_amount]).to eq(budget.debt_amount.to_f)
    expect(result[:available_amount]).to eq(budget.current_amount.to_f)
    expect(result[:percentage_used]).to eq(budget.budget_percentage.to_f)
  end

  it 'reporta el gasto del mes de cada presupuesto' do
    budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 300, type_code: 'expense')

    result = calculator.call

    expect(result).to eq(
      [{ budget_id: budget.id, category_name: budget.name, category_color: 'Purple',
         budget_type: 'cash', debt_amount: 0.0, limit_amount: 0.0,
         available_amount: 700.0, spent_this_month: 300.0, percentage_used: 0.0 }]
    )
  end

  it 'excluye presupuestos inactivos' do
    budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
    budget.update!(active: false)

    expect(calculator.call).to eq([])
  end

  it 'retorna array vacio cuando el usuario no tiene presupuestos' do
    expect(calculator.call).to eq([])
  end

  it 'excluye fondos de ahorro (no son presupuestos de gasto)' do
    make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
    make_savings_fund(user:, goal_amount: 20_000, current_amount: 5_000)

    result = calculator.call

    expect(result.size).to eq(1)
    expect(result.first[:category_name]).to eq('Budget cash')
  end
end
