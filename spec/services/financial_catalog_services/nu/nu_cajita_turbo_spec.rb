# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Nu::NuCajitaTurbo do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('nu_cajita_turbo') }
  it { expect(product.name).to eq('Nu Cajita Turbo') }
  it { expect(product.institution).to eq('Nu') }
  it { expect(product.product_type).to eq(:savings_fund) }
  it { expect(product.active).to be true }
  it { expect(product.accrual_frequency).to eq(:daily) }

  describe '#benefits (CA5)' do
    let(:benefit) { product.benefits.first }

    it 'has a 13% annual yield capped at $25,000 with a transactional requirement' do
      expect(benefit[:type]).to eq(:annual_yield)
      expect(benefit[:value]).to eq(13.0)
      expect(benefit[:amount_cap]).to eq(25_000.0)
      expect(benefit[:requirement]).to include('cualquier tarjeta Nu')
    end
  end
end
