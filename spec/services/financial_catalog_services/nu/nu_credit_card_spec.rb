# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Nu::NuCreditCard do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('nu_credit_card') }
  it { expect(product.name).to eq('Nu Credito') }
  it { expect(product.institution).to eq('Nu') }
  it { expect(product.product_type).to eq(:credit) }
  it { expect(product.active).to be true }
  it { expect(product.benefits).to be_an(Array) }

  it 'includes a cashback benefit' do
    expect(product.benefits).to include(hash_including(type: :cashback))
  end

  it 'has Visa Gold as its network_level' do
    expect(product.network_level).to eq(FinancialNetworks::Visa::Gold)
  end
end
