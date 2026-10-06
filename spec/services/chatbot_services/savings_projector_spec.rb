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

    # El flujo mensual vive en su propio campo, no en el desglose: el desglose son
    # cifras que suman al total y esta es una tasa.
    it 'incluye el gasto obligatorio recurrente en el flujo neto mensual' do
      result = described_class.new(user:, message: 'proyección').calculate

      expect(result.data[:result][:monthly_net_flow]).to eq(-100.0)
    end

    # Ni el aguinaldo ni el fondo de nomina viven en el flujo mensual: el fondo del
    # empleado se descuenta del neto y el del patron nunca toca la cuenta. Si no se
    # suman aqui, se pierden.
    it 'suma aguinaldo y fondo de nómina cuando el horizonte llega a diciembre' do
      create(:employment_information, user:, start_date: Date.new(Date.current.year, 7, 27))
      user.reload.payroll_profile.update!(base_salary: 82_000, savings_fund_rate: 5)

      result = described_class.new(user:, message: "hasta diciembre de #{Date.current.year}")
                              .calculate.data[:result]
      etiquetas = result[:breakdown].map { |row| row[:label] }

      expect(etiquetas).to include(a_string_matching(/Aguinaldo/))
      expect(etiquetas).to include(a_string_matching(/Fondo de ahorro de nómina/))
      expect(result[:breakdown].sum { |row| row[:amount] }.round(2)).to eq(result[:primary_metric])
    end

    it 'no inventa prestaciones cuando el horizonte no llega a diciembre' do
      create(:employment_information, user:, start_date: Date.new(Date.current.year, 7, 27))

      result = described_class.new(user:, message: "hasta marzo de #{Date.current.year + 1}")
                              .calculate.data[:result]

      expect(result[:breakdown].map { |row| row[:label] }).not_to include(a_string_matching(/Aguinaldo/))
    end

    it 'entrega el total ya calculado y su fórmula, para no pedirle aritmética al modelo' do
      result = described_class.new(user:, message: 'proyección').calculate.data[:result]

      expect(result[:metric_label]).to start_with('Total proyectado al')
      expect(result[:formula]).to include('de liquidez')
      expect(result[:breakdown].sum { |row| row[:amount] }.round(2)).to eq(result[:primary_metric])
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
