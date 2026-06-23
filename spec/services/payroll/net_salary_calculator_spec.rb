# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payroll::NetSalaryCalculator, type: :service do
  describe '#call' do
    context 'CA5: salario $20,000 (tramo ISR 6.4%)' do
      subject(:result) { described_class.new(monthly_gross_salary: 20_000).call }

      let(:expected_isr) do
        ((BigDecimal('20000') - BigDecimal('7735.01')) * BigDecimal('0.064') + BigDecimal('148.51')).round(2)
      end
      let(:expected_imss) { (BigDecimal('20000') * BigDecimal('0.0357')).round(2) }

      it 'retorna un resultado exitoso' do
        expect(result).to be_success
      end

      it 'calcula ISR según tabla 2026' do
        expect(result.data[:isr_withholding]).to eq(expected_isr)
      end

      it 'calcula IMSS obrero al 3.57%' do
        expect(result.data[:imss_withholding]).to eq(expected_imss)
      end

      it 'calcula salario neto correcto' do
        expected_net = (BigDecimal('20000') - expected_isr - expected_imss).round(2)
        expect(result.data[:net]).to eq(expected_net)
      end

      it 'incluye salario bruto' do
        expect(result.data[:gross]).to eq(BigDecimal('20000'))
      end
    end

    context 'CA6: salario $50,000 (tramo ISR 6.4%)' do
      subject(:result) { described_class.new(monthly_gross_salary: 50_000).call }

      let(:expected_isr) do
        ((BigDecimal('50000') - BigDecimal('7735.01')) * BigDecimal('0.064') + BigDecimal('148.51')).round(2)
      end
      let(:expected_imss) { (BigDecimal('50000') * BigDecimal('0.0357')).round(2) }

      it 'retorna un resultado exitoso' do
        expect(result).to be_success
      end

      it 'calcula ISR progresivo 2026' do
        expect(result.data[:isr_withholding]).to eq(expected_isr)
      end

      it 'calcula salario neto correcto' do
        expected_net = (BigDecimal('50000') - expected_isr - expected_imss).round(2)
        expect(result.data[:net]).to eq(expected_net)
      end
    end

    context 'salario mínimo ($7,735 o menos, tramo 1.92%)' do
      subject(:result) { described_class.new(monthly_gross_salary: 5_000).call }

      let(:expected_isr) { (BigDecimal('5000') * BigDecimal('0.0192')).round(2) }

      it 'aplica tasa del primer tramo (1.92%)' do
        expect(result.data[:isr_withholding]).to eq(expected_isr)
      end
    end

    context 'salario en tercer tramo ($65,651.08 - $115,375.90, 10.88%)' do
      subject(:result) { described_class.new(monthly_gross_salary: 80_000).call }

      let(:expected_isr) do
        ((BigDecimal('80000') - BigDecimal('65651.08')) * BigDecimal('0.1088') + BigDecimal('3844.44')).round(2)
      end

      it 'aplica tasa del tercer tramo (10.88%)' do
        expect(result.data[:isr_withholding]).to eq(expected_isr)
      end
    end

    context 'salario en tramo máximo (> $3,898,140.13, 35%)' do
      subject(:result) { described_class.new(monthly_gross_salary: 5_000_000).call }

      let(:expected_isr) do
        ((BigDecimal('5000000') - BigDecimal('3898140.13')) * BigDecimal('0.35') + BigDecimal('1222522.17')).round(2)
      end

      it 'aplica tasa máxima del 35%' do
        expect(result.data[:isr_withholding]).to eq(expected_isr)
      end
    end
  end
end
