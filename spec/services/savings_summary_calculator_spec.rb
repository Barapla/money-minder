# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SavingsSummaryCalculator do
  let(:user) { create(:user) }

  subject(:calculator) { described_class.new(user) }

  it 'retorna el progreso de cada fondo de ahorro activo hacia su meta' do
    fund = make_savings_fund(user:, goal_amount: 20_000, current_amount: 5_000, name: 'Fondo Emergencia')

    result = calculator.call

    expect(result).to eq(
      [{ fund_id: fund.id, fund_name: 'Fondo Emergencia', current_amount: 5000.0,
         goal_amount: 20_000.0, percentage_achieved: 25.0,
         target_date: nil, feasibility: 'no_target_date' }]
    )
  end

  it 'excluye fondos inactivos' do
    fund = make_savings_fund(user:, goal_amount: 20_000, current_amount: 5_000)
    fund.update!(active: false)

    expect(calculator.call).to eq([])
  end

  it 'retorna array vacio cuando el usuario no tiene fondos de ahorro' do
    expect(calculator.call).to eq([])
  end
end
