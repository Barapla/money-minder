# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialProductsHelper, type: :helper do
  describe '#requirement_type_badge_class' do
    it 'retorna clase azul para min_transactions' do
      expect(helper.requirement_type_badge_class('min_transactions')).to include('blue')
    end

    it 'retorna clase morada para min_transactions_with_amount' do
      expect(helper.requirement_type_badge_class('min_transactions_with_amount')).to include('purple')
    end

    it 'retorna clase verde para accumulated_amount' do
      expect(helper.requirement_type_badge_class('accumulated_amount')).to include('emerald')
    end

    it 'retorna clase ambar para monthly_fee' do
      expect(helper.requirement_type_badge_class('monthly_fee')).to include('amber')
    end

    it 'retorna clase gris para tipo desconocido' do
      expect(helper.requirement_type_badge_class('unknown')).to include('bunker')
    end

    it 'acepta simbolos como argumento' do
      expect(helper.requirement_type_badge_class(:min_transactions)).to include('blue')
    end
  end

  describe '#format_requirement_description' do
    let(:benefit) { build(:financial_product_benefit) }

    context 'tipo min_transactions' do
      let(:req) { build(:financial_product_benefit_requirement, :min_transactions, min_transactions_count: 1) }

      it 'describe transacciones sin monto minimo' do
        result = helper.format_requirement_description(req)
        expect(result).to include('1')
      end
    end

    context 'tipo min_transactions_with_amount' do
      let(:req) do
        build(:financial_product_benefit_requirement, :min_transactions_with_amount,
              min_transactions_count: 4, min_amount_per_transaction: 50.00)
      end

      it 'describe transacciones con monto minimo' do
        result = helper.format_requirement_description(req)
        expect(result).to include('4')
        expect(result).to include('50')
      end
    end

    context 'tipo accumulated_amount' do
      let(:req) do
        build(:financial_product_benefit_requirement, :accumulated_amount,
              min_accumulated_amount: 2500.00)
      end

      it 'describe monto acumulado' do
        result = helper.format_requirement_description(req)
        expect(result).to include('2,500')
      end
    end

    context 'tipo monthly_fee' do
      let(:req) do
        build(:financial_product_benefit_requirement, :monthly_fee, monthly_fee_amount: 179.00)
      end

      it 'describe cuota mensual' do
        result = helper.format_requirement_description(req)
        expect(result).to include('179')
      end
    end
  end
end
