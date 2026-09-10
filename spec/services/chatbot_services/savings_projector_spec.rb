# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::SavingsProjector, type: :service do
  let(:user) { create(:user) }

  context 'CA4: sin pagos obligatorios registrados' do
    before { make_budget(user:, type_code: 'cash', amount: 1000, personal: true) }

    it 'advierte que los datos podrian estar incompletos' do
      result = described_class.new(user:, message: '¿Cuánto habré ahorrado para junio 2027?').calculate
      expect(result.data[:warnings]).to include(a_string_matching(/pagos obligatorios/i))
    end
  end

  context 'CA4: con pagos obligatorios registrados' do
    before do
      make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
      make_obligatory_payment(user:, amount: 100, recurring: true, frequency_code: 'monthly', frequency_value: 1)
    end

    it 'no advierte sobre datos incompletos' do
      result = described_class.new(user:, message: '¿Cuánto habré ahorrado para junio 2027?').calculate
      expect(result.data[:warnings]).to be_empty
    end

    it 'incluye el gasto obligatorio recurrente en el flujo neto mensual' do
      projector = described_class.new(user:, message: 'proyección')
      expect(projector.monthly_net_flow).to eq(-100.0)
    end
  end

  context 'sin fecha explicita en el mensaje' do
    before { make_budget(user:, type_code: 'cash', amount: 1000, personal: true) }

    it 'usa un horizonte por defecto de 6 meses' do
      result = described_class.new(user:, message: '¿Cuánto habré ahorrado?').calculate
      expect(result.data[:assumptions].join).to match(/#{6.months.from_now.to_date.strftime('%m/%Y')}/)
    end
  end
end
