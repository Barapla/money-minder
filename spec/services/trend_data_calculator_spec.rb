# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrendDataCalculator do
  let(:user) { create(:user) }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 0, personal: true) }
  let(:category) { category_for('Comida') }

  subject(:calculator) { described_class.new(user) }

  it 'retorna 6 meses ordenados cronologicamente terminando en el mes actual' do
    result = calculator.call

    expect(result.length).to eq(6)
    expect(result.last[:month]).to eq(Date.current.strftime('%Y-%m'))
    expect(result.first[:month]).to eq((Date.current - 5.months).strftime('%Y-%m'))
  end

  it 'agrupa ingresos y gastos por mes y calcula el balance' do
    make_transaction(user:, budget:, category:, amount: 1000, type_code: 'income', transaction_date: Date.current)
    make_transaction(user:, budget:, category:, amount: 400, type_code: 'expense', transaction_date: Date.current)
    make_transaction(user:, budget:, category:, amount: 200, type_code: 'expense',
                     transaction_date: 1.month.ago.to_date)

    result = calculator.call

    expect(result.last).to eq(month: Date.current.strftime('%Y-%m'), income: 1000.0, expenses: 400.0, balance: 600.0)
    previous_month = 1.month.ago.to_date.strftime('%Y-%m')
    expect(result.find { |entry| entry[:month] == previous_month }).to eq(
      month: previous_month, income: 0.0, expenses: 200.0, balance: -200.0
    )
  end

  it 'ignora transacciones fuera de la ventana de 6 meses' do
    make_transaction(user:, budget:, category:, amount: 5000, type_code: 'expense',
                     transaction_date: 8.months.ago.to_date)

    result = calculator.call

    expect(result.sum { |entry| entry[:expenses] }).to eq(0.0)
  end

  it 'retorna ceros cuando el usuario no tiene transacciones' do
    result = calculator.call

    expect(result).to all(include(income: 0.0, expenses: 0.0, balance: 0.0))
  end
end
