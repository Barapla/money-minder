# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecentTransactionsCalculator do
  let(:user) { create(:user) }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 0, personal: true) }
  let(:category) { category_for('Comida') }

  subject(:calculator) { described_class.new(user) }

  it 'retorna las transacciones ordenadas por transaction_date DESC' do
    older = make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense',
                             transaction_date: 2.days.ago.to_date)
    newer = make_transaction(user:, budget:, category:, amount: 200, type_code: 'expense',
                             transaction_date: Date.current)

    result = calculator.call

    expect(result.map { |entry| entry[:id] }).to eq([newer.id, older.id])
    expect(result.first).to eq(
      id: newer.id, description: newer.description, amount: 200.0, currency: newer.currency.code,
      transaction_date: Date.current, category_name: 'Comida', category_color: category.color&.value,
      transaction_type: 'expense'
    )
  end

  it 'limita el resultado a 10 transacciones' do
    12.times do |i|
      make_transaction(user:, budget:, category:, amount: 10, type_code: 'expense',
                       transaction_date: i.days.ago.to_date)
    end

    expect(calculator.call.length).to eq(10)
  end

  it 'retorna array vacio cuando el usuario no tiene transacciones' do
    expect(calculator.call).to eq([])
  end
end
