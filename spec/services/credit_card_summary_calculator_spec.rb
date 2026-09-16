# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditCardSummaryCalculator do
  let(:user) { create(:user) }

  subject(:calculator) { described_class.new(user) }

  it 'retorna el resumen de tarjetas de credito activas ordenadas por next_cutting_date' do
    card_a = make_credit_card(user:, limit_amount: 10_000, name: 'Tarjeta A', cutting_day: 25)
    card_b = make_credit_card(user:, limit_amount: 5_000, name: 'Tarjeta B', cutting_day: 1)
    expected_order = [card_a, card_b].sort_by(&:next_cutting_date).map(&:id)

    result = calculator.call

    expect(result.map { |entry| entry[:card_id] }).to eq(expected_order)
    expect(result.first.keys).to contain_exactly(
      :card_id, :card_name, :current_balance, :credit_limit, :available_credit,
      :next_cutting_date, :next_payment_date
    )
  end

  it 'excluye tarjetas inactivas' do
    card = make_credit_card(user:, limit_amount: 10_000, name: 'Tarjeta inactiva', cutting_day: 10)
    card.update!(active: false)

    expect(calculator.call).to eq([])
  end

  it 'retorna array vacio cuando el usuario no tiene tarjetas de credito' do
    expect(calculator.call).to eq([])
  end
end
