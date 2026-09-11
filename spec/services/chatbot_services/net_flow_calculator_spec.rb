# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::NetFlowCalculator, type: :service do
  let(:user) { create(:user) }

  it 'calcula el flujo neto mensual con la suma en base de datos por frecuencia' do
    make_recurring_transaction(user:, type_code: 'income', amount: 1000, frequency: 'monthly')
    make_recurring_transaction(user:, type_code: 'expense', amount: 100, frequency: 'weekly')
    make_obligatory_payment(user:, amount: 50, recurring: true, frequency_code: 'monthly', frequency_value: 1)

    net_flow = described_class.new(user).monthly_net_flow

    expect(net_flow).to be_within(0.01).of(1000 - (100 * 4.33) - 50)
  end
end
