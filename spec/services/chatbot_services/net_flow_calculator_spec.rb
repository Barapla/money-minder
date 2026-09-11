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

  it 'incluye el sueldo de nomina cuando el usuario no registra su ingreso como recurring_transaction' do
    create(:employment_information, user:, payment_frequency: 'weekly_payment',
                                    calculation_periodicity: 'monthly_calculation', gross_salary_amount: 33_000.00)
    payroll_profile = user.reload.payroll_profile
    payroll_profile.update!(savings_fund_rate: 4.0, custom_isr_rate: 18.6, custom_imss_rate: 3.0)
    make_obligatory_payment(user:, amount: 500, recurring: true, frequency_code: 'monthly', frequency_value: 1)

    net_flow = described_class.new(user).monthly_net_flow
    net_salary = PayrollServices::Calculator.new(payroll_profile).call.data[:net_salary].to_f

    expect(net_flow).to be_within(0.01).of(net_salary - 500)
  end
end
