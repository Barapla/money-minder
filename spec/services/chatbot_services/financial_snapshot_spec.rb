# frozen_string_literal: true

require 'rails_helper'

# La foto que se manda a Claude en toda consulta. Nacio de dos fallas reales:
# la nomina no llegaba nunca, y cada calculador armaba su propia base.
RSpec.describe ChatbotServices::FinancialSnapshot, type: :service do
  let(:user) { create(:user) }

  describe 'sin datos de empleo' do
    it 'manda los saldos aunque no haya nómina configurada' do
      prompt = described_class.new(user).to_prompt

      expect(prompt).to include('SALDOS HOY')
      expect(prompt).not_to include('NÓMINA (')
      expect(prompt).not_to include('PRESTACIONES')
    end
  end

  describe 'con empleo y perfil de nómina' do
    let(:horizonte) { Date.new(Date.current.year, 12, 25) }

    # EmploymentInformation crea el PayrollProfile por callback, y este es unico
    # por usuario: hay que actualizar el que quedo, no crear otro.
    before do
      create(:employment_information, user:, start_date: Date.new(Date.current.year, 7, 27))
      profile = user.reload.payroll_profile || create(:payroll_profile, user:)
      profile.update!(base_salary: 82_000, savings_fund_rate: 5)
    end

    # El bug central: la nomina no es un ObligatoryPayment, asi que el resumen de
    # recordatorios la ignoraba y el bot concluia que el usuario no tiene ingresos.
    it 'incluye la nómina, que no vive en los recordatorios' do
      prompt = described_class.new(user, horizon_date: horizonte).to_prompt

      expect(prompt).to include('NÓMINA')
      expect(prompt).to include('NO está en los recordatorios')
    end

    it 'incluye aguinaldo proporcional y fondo de ahorro' do
      snapshot = described_class.new(user, horizon_date: horizonte)

      expect(snapshot.to_prompt).to include('PRESTACIONES')
      expect(snapshot.to_prompt).to include('aguinaldo')
      expect(snapshot.aguinaldo).to be_success
      expect(snapshot.aguinaldo.data[:proportional]).to be(true)
      expect(snapshot.savings_fund.data[:employee_contribution]).to eq(BigDecimal('4100'))
    end

    # NetFlowCalculator ya mete la nomina en el flujo mensual: sin este aviso,
    # Claude sumaba la nomina del snapshot encima de la proyeccion.
    # La nota larga traia dos reglas opuestas y el modelo las invirtio: dio por
    # incluido el aguinaldo, que no lo estaba. Ahora es una sola instruccion.
    it 'prohíbe recalcular sobre el contexto, sin excepciones que confundan' do
      prompt = described_class.new(user, horizon_date: horizonte).to_prompt

      expect(prompt).to include('no sumes ni restes nada de aquí encima')
      expect(prompt).not_to include('El aguinaldo sí es extra')
    end

    it 'proyecta la nómina al horizonte que se le pide' do
      corto = described_class.new(user, horizon_date: Date.current + 7.days).payroll_total
      largo = described_class.new(user, horizon_date: horizonte).payroll_total

      expect(largo).to be > corto
    end
  end
end
