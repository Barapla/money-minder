# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Nu::NuFrozenSavings90 do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('nu_frozen_savings90') }
  it { expect(product.name).to eq('Congelado 90 dias') }
  it { expect(product.institution).to eq('Nu') }
  it { expect(product.product_type).to eq(:term_saving) }
  it { expect(product.active).to be true }
  it { expect(product.accrual_frequency).to eq(:daily) }

  it 'includes an annual_yield benefit' do
    expect(product.benefits).to include(hash_including(type: :annual_yield, value: 12.0))
  end
end
