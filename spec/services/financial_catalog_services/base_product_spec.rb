# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::BaseProduct do
  subject(:product) do
    described_class.new(
      name: 'Test Product',
      institution: 'Test Bank',
      product_type: :debit,
      benefits: [{ type: :cashback, value: 2.0 }]
    )
  end

  it { expect(product.id).to eq('base_product') }
  it { expect(product.name).to eq('Test Product') }
  it { expect(product.institution).to eq('Test Bank') }
  it { expect(product.product_type).to eq(:debit) }
  it { expect(product.benefits).to eq([{ type: :cashback, value: 2.0 }]) }

  it 'defaults active to true' do
    expect(described_class.new(name: 'X', institution: 'Y', product_type: :cash).active).to be true
  end

  it 'defaults benefits to an empty array' do
    expect(described_class.new(name: 'X', institution: 'Y', product_type: :cash).benefits).to eq([])
  end

  it 'allows overriding active' do
    inactive = described_class.new(name: 'X', institution: 'Y', product_type: :cash, active: false)
    expect(inactive.active).to be false
  end

  it 'defaults network_level to nil' do
    expect(product.network_level).to be_nil
  end

  it 'defaults accrual_frequency to :at_maturity' do
    expect(product.accrual_frequency).to eq(:at_maturity)
  end

  it 'only allows :daily or :at_maturity as accrual frequencies' do
    expect(FinancialCatalogServices::BaseProduct::ALLOWED_ACCRUAL_FREQUENCIES).to contain_exactly(:daily, :at_maturity)
  end

  it 'every catalog product declares an allowed accrual frequency' do
    frequencies = FinancialCatalogServices::Catalog.all_products.map(&:accrual_frequency)

    expect(frequencies).to all(be_in(FinancialCatalogServices::BaseProduct::ALLOWED_ACCRUAL_FREQUENCIES))
  end
end
