# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialProductBenefitRequirement, type: :model do
  subject(:requirement) { build(:financial_product_benefit_requirement) }

  describe 'asociaciones' do
    it { is_expected.to belong_to(:benefit).class_name('FinancialProductBenefit') }
  end

  describe 'enums' do
    it 'define requirement_type con los valores correctos' do
      expect(described_class.requirement_types).to eq(
        'min_transactions' => 0,
        'min_transactions_with_amount' => 1,
        'accumulated_amount' => 2,
        'monthly_fee' => 3
      )
    end
  end

  describe 'validaciones' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:requirement_type) }

    context 'tipo min_transactions' do
      subject(:requirement) { build(:financial_product_benefit_requirement, :min_transactions) }

      it 'es valido con min_transactions_count mayor que 0' do
        requirement.min_transactions_count = 1
        expect(requirement).to be_valid
      end

      it 'rechaza min_transactions_count nil' do
        requirement.min_transactions_count = nil
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_transactions_count]).to be_present
      end

      it 'rechaza min_transactions_count cero' do
        requirement.min_transactions_count = 0
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_transactions_count]).to be_present
      end

      it 'rechaza min_transactions_count negativo' do
        requirement.min_transactions_count = -1
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_transactions_count]).to be_present
      end

      it 'rechaza min_transactions_count decimal' do
        requirement.min_transactions_count = 1.5
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_transactions_count]).to be_present
      end

      it 'no requiere min_amount_per_transaction' do
        requirement.min_amount_per_transaction = nil
        expect(requirement).to be_valid
      end
    end

    context 'tipo min_transactions_with_amount' do
      subject(:requirement) { build(:financial_product_benefit_requirement, :min_transactions_with_amount) }

      it 'es valido con todos los campos requeridos' do
        expect(requirement).to be_valid
      end

      it 'rechaza min_transactions_count nil' do
        requirement.min_transactions_count = nil
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_transactions_count]).to be_present
      end

      it 'rechaza min_transactions_count cero' do
        requirement.min_transactions_count = 0
        expect(requirement).not_to be_valid
      end

      it 'rechaza min_amount_per_transaction nil' do
        requirement.min_amount_per_transaction = nil
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_amount_per_transaction]).to be_present
      end

      it 'rechaza min_amount_per_transaction cero' do
        requirement.min_amount_per_transaction = 0
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_amount_per_transaction]).to be_present
      end

      it 'rechaza min_amount_per_transaction negativo' do
        requirement.min_amount_per_transaction = -50
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_amount_per_transaction]).to be_present
      end
    end

    context 'tipo accumulated_amount' do
      subject(:requirement) { build(:financial_product_benefit_requirement, :accumulated_amount) }

      it 'es valido con min_accumulated_amount mayor que 0' do
        expect(requirement).to be_valid
      end

      it 'rechaza min_accumulated_amount nil' do
        requirement.min_accumulated_amount = nil
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_accumulated_amount]).to be_present
      end

      it 'rechaza min_accumulated_amount cero' do
        requirement.min_accumulated_amount = 0
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_accumulated_amount]).to be_present
      end

      it 'rechaza min_accumulated_amount negativo' do
        requirement.min_accumulated_amount = -100
        expect(requirement).not_to be_valid
        expect(requirement.errors[:min_accumulated_amount]).to be_present
      end

      it 'no requiere min_transactions_count' do
        requirement.min_transactions_count = nil
        expect(requirement).to be_valid
      end
    end

    context 'tipo monthly_fee' do
      subject(:requirement) { build(:financial_product_benefit_requirement, :monthly_fee) }

      it 'es valido con monthly_fee_amount mayor que 0' do
        expect(requirement).to be_valid
      end

      it 'rechaza monthly_fee_amount nil' do
        requirement.monthly_fee_amount = nil
        expect(requirement).not_to be_valid
        expect(requirement.errors[:monthly_fee_amount]).to be_present
      end

      it 'rechaza monthly_fee_amount cero' do
        requirement.monthly_fee_amount = 0
        expect(requirement).not_to be_valid
        expect(requirement.errors[:monthly_fee_amount]).to be_present
      end

      it 'rechaza monthly_fee_amount negativo' do
        requirement.monthly_fee_amount = -179
        expect(requirement).not_to be_valid
        expect(requirement.errors[:monthly_fee_amount]).to be_present
      end

      it 'no requiere min_transactions_count' do
        requirement.min_transactions_count = nil
        expect(requirement).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:benefit) { create(:financial_product_benefit) }

    before do
      create(:financial_product_benefit_requirement, benefit:, active: true)
      create(:financial_product_benefit_requirement, benefit:, active: false)
    end

    describe '.active' do
      it 'retorna solo requisitos activos' do
        active_reqs = benefit.requirements.active
        expect(active_reqs.count).to eq(1)
        expect(active_reqs.all?(&:active?)).to be true
      end
    end
  end
end
