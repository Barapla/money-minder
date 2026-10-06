# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::CardStatusChecker, type: :service do
  let(:user) { create(:user) }

  context 'CA6: con una tarjeta que coincide por nombre' do
    before { make_credit_card(user:, name: 'Banamex Oro', limit_amount: 20_000) }

    it 'retorna saldo, limite, fecha de corte y dias hasta el pago' do
      result = described_class.new(user:, message: '¿En qué va mi ciclo de Banamex Oro?').calculate

      expect(result).to be_success
      labels = result.data[:result][:breakdown].map { |b| b[:label] }
      expect(labels).to include('Tarjeta', 'Límite de crédito', 'Saldo actual del ciclo', 'Próxima fecha de corte',
                                'Días hasta el pago')
    end
  end

  context 'con una sola tarjeta activa y sin coincidencia textual' do
    before { make_credit_card(user:, name: 'Única tarjeta', limit_amount: 10_000) }

    it 'usa esa tarjeta por default' do
      result = described_class.new(user:, message: '¿en qué va mi ciclo?').calculate
      expect(result).to be_success
    end
  end

  context 'sin tarjetas de credito' do
    it 'retorna un Result fallido pidiendo el nombre de la tarjeta' do
      result = described_class.new(user:, message: '¿en qué va mi ciclo de HSBC?').calculate
      expect(result).to be_failure
      expect(result.message).to match(/no encontramos una tarjeta/i)
    end
  end
end
