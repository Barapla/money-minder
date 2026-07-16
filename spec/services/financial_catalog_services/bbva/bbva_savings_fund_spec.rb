# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Bbva::BbvaSavingsFund do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.name).to eq('Ahorro Digital') }
  it { expect(product.institution).to eq('BBVA') }
  it { expect(product.product_type).to eq(:savings_fund) }
  it { expect(product.active).to be true }

  it 'includes an annual_yield benefit' do
    expect(product.benefits).to include(hash_including(type: :annual_yield))
  end
end
