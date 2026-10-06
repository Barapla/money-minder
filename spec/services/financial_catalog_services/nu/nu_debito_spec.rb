# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Nu::NuDebito do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('nu_debito') }
  it { expect(product.name).to eq('Nu Debito') }
  it { expect(product.institution).to eq('Nu') }
  it { expect(product.product_type).to eq(:debit) }
  it { expect(product.active).to be true }
  it { expect(product.benefits).to be_empty }
end
