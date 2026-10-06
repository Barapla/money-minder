# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::CategoryAnalyzer, type: :service do
  let(:user) { create(:user) }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 1000, personal: true) }

  context 'CA5: con gastos en varias categorias este mes' do
    before do
      gastos = category_for('Gastos')
      restaurantes = category_for('Restaurantes', parent: gastos)
      transporte = category_for('Transporte', parent: gastos)
      make_transaction(user:, budget:, category: restaurantes, amount: 300, type_code: 'expense')
      make_transaction(user:, budget:, category: transporte, amount: 100, type_code: 'expense')
    end

    it 'agrupa por categoria con totales y porcentajes' do
      result = described_class.new(user:).calculate

      expect(result).to be_success
      expect(result.data[:result][:primary_metric]).to eq(400.0)

      restaurantes_row = result.data[:result][:breakdown].find { |b| b[:label] == 'Restaurantes' }
      expect(restaurantes_row[:amount]).to eq(300.0)
      expect(restaurantes_row[:percentage]).to eq(75.0)
    end
  end

  context 'sin gastos en el periodo' do
    it 'advierte que no hay gastos registrados' do
      result = described_class.new(user:).calculate
      expect(result.data[:warnings]).to include(a_string_matching(/no se encontraron gastos/i))
    end
  end
end
