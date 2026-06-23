# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payroll::AguinaldoCalculator, type: :service do
  let(:salary) { BigDecimal('30000') }
  let(:base_date) { Date.new(2026, 6, 23) }

  describe '#call' do
    context 'CA1: usuario con 2 años completos de antigüedad' do
      subject(:result) do
        described_class.new(
          monthly_gross_salary: salary,
          hire_date: base_date - 2.years,
          calculation_date: base_date
        ).call
      end

      it 'retorna un resultado exitoso' do
        expect(result).to be_success
      end

      it 'calcula aguinaldo de 2 años (15 días × 2)' do
        expect(result.data[:amount]).to eq(BigDecimal('30000'))
      end

      it 'indica que no es proporcional' do
        expect(result.data[:proportional]).to be(false)
      end
    end

    context 'CA2: usuario con 182 días de antigüedad (proporcional)' do
      subject(:result) do
        described_class.new(
          monthly_gross_salary: salary,
          hire_date: base_date - 182,
          calculation_date: base_date
        ).call
      end

      it 'retorna un resultado exitoso' do
        expect(result).to be_success
      end

      it 'calcula aguinaldo proporcional' do
        expected = (BigDecimal('30000') / 30 * 15 * 182 / BigDecimal('365')).round(2)
        expect(result.data[:amount]).to eq(expected)
      end

      it 'indica que es proporcional' do
        expect(result.data[:proportional]).to be(true)
      end
    end

    context 'caso límite: 0 días trabajados' do
      subject(:result) do
        described_class.new(
          monthly_gross_salary: salary,
          hire_date: base_date,
          calculation_date: base_date
        ).call
      end

      it 'retorna resultado exitoso con monto cero' do
        expect(result).to be_success
        expect(result.data[:amount]).to eq(BigDecimal('0'))
      end
    end

    context 'caso límite: 364 días (antes de completar un año)' do
      subject(:result) do
        described_class.new(
          monthly_gross_salary: salary,
          hire_date: base_date - 364,
          calculation_date: base_date
        ).call
      end

      it 'calcula proporcional' do
        expect(result.data[:proportional]).to be(true)
      end
    end

    context 'caso límite: exactamente 365 días (un año completo)' do
      subject(:result) do
        described_class.new(
          monthly_gross_salary: salary,
          hire_date: base_date - 365,
          calculation_date: base_date
        ).call
      end

      it 'calcula por años completos' do
        expect(result.data[:proportional]).to be(false)
        expect(result.data[:amount]).to eq(BigDecimal('15000'))
      end
    end

    context 'cuando la fecha de cálculo es anterior a la fecha de ingreso' do
      subject(:result) do
        described_class.new(
          monthly_gross_salary: salary,
          hire_date: base_date + 10,
          calculation_date: base_date
        ).call
      end

      it 'retorna resultado fallido' do
        expect(result).to be_failure
      end
    end
  end
end
