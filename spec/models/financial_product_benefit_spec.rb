# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialProductBenefit, type: :model do
  subject(:benefit) { build(:financial_product_benefit) }

  describe 'asociaciones' do
    it { is_expected.to belong_to(:financial_product) }
    it { is_expected.to have_many(:requirements).class_name('FinancialProductBenefitRequirement').dependent(:destroy) }
  end

  describe 'enums' do
    it 'define benefit_type con los valores correctos' do
      expect(described_class.benefit_types).to eq(
        'annual_yield' => 0, 'cashback' => 1, 'points' => 2, 'discount' => 3
      )
    end

    it 'define unit con los valores correctos' do
      expect(described_class.units).to eq(
        'percentage' => 0, 'points' => 1, 'fixed_amount' => 2
      )
    end

    it 'define requirements_logic con los valores correctos' do
      expect(described_class.requirements_logics).to eq('all' => 0, 'any' => 1)
    end

    it 'usa requirements_all? como prefijo para all' do
      benefit.requirements_logic = :all
      expect(benefit.requirements_all?).to be true
      expect(benefit.requirements_any?).to be false
    end

    it 'usa requirements_any? como prefijo para any' do
      benefit.requirements_logic = :any
      expect(benefit.requirements_any?).to be true
      expect(benefit.requirements_all?).to be false
    end
  end

  describe 'validaciones' do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:benefit_type) }
    it { is_expected.to validate_presence_of(:base_value) }
    it { is_expected.to validate_presence_of(:unit) }

    it 'rechaza base_value cero' do
      benefit.base_value = 0
      expect(benefit).not_to be_valid
      expect(benefit.errors[:base_value]).to be_present
    end

    it 'rechaza base_value negativo' do
      benefit.base_value = -1
      expect(benefit).not_to be_valid
      expect(benefit.errors[:base_value]).to be_present
    end

    it 'acepta reduced_value nil' do
      benefit.reduced_value = nil
      expect(benefit).to be_valid
    end

    it 'rechaza reduced_value cero' do
      benefit.reduced_value = 0
      expect(benefit).not_to be_valid
      expect(benefit.errors[:reduced_value]).to be_present
    end

    it 'acepta amount_cap nil' do
      benefit.amount_cap = nil
      expect(benefit).to be_valid
    end

    it 'rechaza amount_cap cero' do
      benefit.amount_cap = 0
      expect(benefit).not_to be_valid
      expect(benefit.errors[:amount_cap]).to be_present
    end

    context 'cuando la unidad es porcentaje' do
      before { benefit.unit = :percentage }

      it 'rechaza base_value mayor a 100' do
        benefit.base_value = 101
        expect(benefit).not_to be_valid
        expect(benefit.errors[:base_value]).to be_present
      end

      it 'acepta base_value de 100' do
        benefit.base_value = 100
        expect(benefit).to be_valid
      end

      it 'rechaza reduced_value mayor a 100' do
        benefit.reduced_value = 150
        expect(benefit).not_to be_valid
        expect(benefit.errors[:reduced_value]).to be_present
      end

      it 'acepta reduced_value valido entre 0 y 100' do
        benefit.reduced_value = 7.0
        expect(benefit).to be_valid
      end
    end

    context 'cuando la unidad no es porcentaje' do
      before { benefit.unit = :fixed_amount }

      it 'acepta base_value mayor a 100' do
        benefit.base_value = 5000
        expect(benefit).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:product) { create(:financial_product) }

    before do
      create(:financial_product_benefit, financial_product: product, active: true)
      create(:financial_product_benefit, financial_product: product, active: false)
    end

    describe '.active' do
      it 'retorna solo beneficios activos' do
        active_benefits = product.benefits.active
        expect(active_benefits.count).to eq(1)
        expect(active_benefits.all?(&:active?)).to be true
      end
    end
  end

  describe 'metodos de instancia de enum con prefix' do
    it 'usa unit_percentage? para verificar unidad de porcentaje' do
      benefit.unit = :percentage
      expect(benefit.unit_percentage?).to be true
      expect(benefit.unit_points?).to be false
    end

    it 'usa unit_points? para verificar unidad de puntos' do
      benefit.unit = :points
      expect(benefit.unit_points?).to be true
      expect(benefit.unit_percentage?).to be false
    end

    it 'usa points? para verificar tipo de beneficio puntos' do
      benefit.benefit_type = :points
      expect(benefit.points?).to be true
      expect(benefit.annual_yield?).to be false
    end
  end
end
