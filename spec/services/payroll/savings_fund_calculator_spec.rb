# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payroll::SavingsFundCalculator, type: :service do
  let(:uma_cap) { (BigDecimal('113.14') * BigDecimal('30.4') * BigDecimal('1.3')).round(2) }

  describe '#call' do
    context 'CA3: salario $30,000 con 13% (sin exceder tope)' do
      subject(:result) do
        described_class.new(monthly_gross_salary: 30_000, savings_fund_percentage: 13).call
      end

      let(:expected_contribution) { BigDecimal('3900') }

      it 'retorna un resultado exitoso' do
        expect(result).to be_success
      end

      it 'calcula contribución sin aplicar tope UMA' do
        expect(result.data[:employee_contribution]).to eq(expected_contribution)
        expect(result.data[:employer_contribution]).to eq(expected_contribution)
      end

      it 'no aplica tope UMA' do
        expect(result.data[:uma_cap_applied]).to be(false)
      end

      it 'calcula el total mensual' do
        expect(result.data[:monthly_total]).to eq((expected_contribution * 2).round(2))
      end
    end

    context 'CA3/CA4: salario $50,000 con 13% (excede tope UMA)' do
      subject(:result) do
        described_class.new(monthly_gross_salary: 50_000, savings_fund_percentage: 13).call
      end

      it 'retorna un resultado exitoso' do
        expect(result).to be_success
      end

      it 'aplica tope UMA' do
        expect(result.data[:uma_cap_applied]).to be(true)
      end

      it 'limita contribución al tope 1.3x UMA mensual' do
        expect(result.data[:employee_contribution]).to eq(uma_cap)
        expect(result.data[:employer_contribution]).to eq(uma_cap)
      end
    end

    context 'CA4: salario $100,000 con 13% (excede ampliamente el tope)' do
      subject(:result) do
        described_class.new(monthly_gross_salary: 100_000, savings_fund_percentage: 13).call
      end

      it 'aplica tope UMA' do
        expect(result.data[:uma_cap_applied]).to be(true)
        expect(result.data[:employee_contribution]).to eq(uma_cap)
      end
    end

    context 'con porcentaje 0%' do
      subject(:result) do
        described_class.new(monthly_gross_salary: 30_000, savings_fund_percentage: 0).call
      end

      it 'retorna contribución cero' do
        expect(result.data[:employee_contribution]).to eq(BigDecimal('0'))
        expect(result.data[:uma_cap_applied]).to be(false)
      end
    end
  end
end
