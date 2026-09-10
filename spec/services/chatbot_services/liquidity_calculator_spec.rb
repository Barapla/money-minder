# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::LiquidityCalculator, type: :service do
  let(:user) { create(:user) }
  let(:calculator) { described_class.new(user:) }

  context 'CA3: con efectivo, debito y fondos de ahorro' do
    before do
      make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
      make_budget(user:, type_code: 'debit_card', amount: 500)
    end

    it 'retorna un Result exitoso con el total y el desglose' do
      result = calculator.calculate

      expect(result).to be_success
      expect(result.data[:result][:primary_metric]).to eq(1500.0)
      labels = result.data[:result][:breakdown].map { |b| b[:label] }
      expect(labels).to include('Efectivo', 'Débito', 'Fondos de ahorro', 'Deuda de tarjetas de crédito')
    end

    it 'incluye supuestos explicitos' do
      result = calculator.calculate
      expect(result.data[:assumptions]).not_to be_empty
    end

    it 'no incluye advertencias cuando la liquidez es positiva' do
      result = calculator.calculate
      expect(result.data[:warnings]).to be_empty
    end
  end

  context 'cuando la deuda de tarjetas supera la liquidez' do
    it 'advierte sobre el saldo negativo' do
      allow(SavingGoalServices::ProgressCalculator).to receive(:new).and_wrap_original do |method, u|
        calc = method.call(u)
        allow(calc).to receive_messages(cash_balance: 0.0, debit_balance: 0.0, savings_balance: 0.0, credit_debt: 100.0,
                                        total_available_money: -100.0)
        calc
      end

      result = calculator.calculate
      expect(result.data[:warnings]).to include(a_string_matching(/deuda/i))
    end
  end
end
