# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Nu::NuCajita do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('nu_cajita') }
  it { expect(product.name).to eq('Nu Cajita') }
  it { expect(product.institution).to eq('Nu') }
  it { expect(product.product_type).to eq(:savings_fund) }
  it { expect(product.active).to be true }
  it { expect(product.accrual_frequency).to eq(:daily) }

  describe '#benefits (CA4)' do
    let(:benefit) { product.benefits.first }

    it 'has a single 6.50% annual yield with no requirements' do
      expect(product.benefits.size).to eq(1)
      expect(benefit[:type]).to eq(:annual_yield)
      expect(benefit[:value]).to eq(6.50)
    end
  end
end
