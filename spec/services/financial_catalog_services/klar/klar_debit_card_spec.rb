# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Klar::KlarDebitCard do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('klar_debit_card') }
  it { expect(product.name).to eq('Klar Debito') }
  it { expect(product.institution).to eq('Klar') }
  it { expect(product.product_type).to eq(:debit) }
  it { expect(product.active).to be true }

  it 'includes an annual_yield benefit with an amount cap' do
    expect(product.benefits).to include(hash_including(type: :annual_yield, amount_cap: 25_000.0))
  end
end
