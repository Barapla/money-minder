# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::ScenarioSimulator, type: :service do
  let(:user) { create(:user) }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 1000, personal: true) }

  context 'CA7: recorte porcentual sobre una categoria existente' do
    before do
      gastos = category_for('Gastos')
      restaurantes = category_for('Restaurantes', parent: gastos)
      make_transaction(user:, budget:, category: restaurantes, amount: 1000, type_code: 'expense')
    end

    it 'proyecta un escenario ajustado distinto al escenario base' do
      result = described_class.new(user:, message: '¿Y si recorto restaurantes 30%?').calculate

      expect(result).to be_success
      breakdown = result.data[:result][:breakdown]
      base = breakdown.find { |b| b[:label] == 'Escenario base (sin cambios)' }[:amount]
      adjusted = result.data[:result][:breakdown].find { |b| b[:label] == 'Escenario ajustado' }[:amount]

      expect(adjusted).to be > base
      expect(result.data[:warnings]).to be_empty
    end
  end

  context 'cuando la categoria mencionada no existe en los gastos del mes' do
    it 'advierte que no se encontro la categoria' do
      result = described_class.new(user:, message: '¿Y si recorto viajes 30%?').calculate
      expect(result.data[:warnings]).to include(a_string_matching(/no se encontró la categoría/i))
    end
  end
end
