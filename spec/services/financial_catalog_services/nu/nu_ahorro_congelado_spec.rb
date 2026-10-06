# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Nu::NuAhorroCongelado do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('nu_ahorro_congelado') }
  it { expect(product.name).to eq('Nu Ahorro Congelado') }
  it { expect(product.institution).to eq('Nu') }
  it { expect(product.product_type).to eq(:term_saving) }
  it { expect(product.active).to be true }
  it { expect(product.accrual_frequency).to eq(:at_maturity) }

  describe '#benefits (CA6)' do
    it 'defines the four term tiers, none allowing early withdrawal' do
      expect(product.benefits).to contain_exactly(
        hash_including(term_days: 7, min_amount: 50.0, early_withdrawal: false),
        hash_including(term_days: 28, min_amount: 50.0, early_withdrawal: false),
        hash_including(term_days: 90, min_amount: 50.0, early_withdrawal: false),
        hash_including(term_days: 180, min_amount: 50.0, early_withdrawal: false)
      )
    end
  end
end
