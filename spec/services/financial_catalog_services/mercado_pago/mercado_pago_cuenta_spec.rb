# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::MercadoPago::MercadoPagoCuenta do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('mercado_pago_cuenta') }
  it { expect(product.name).to eq('Mercado Pago') }
  it { expect(product.institution).to eq('Mercado Pago') }
  it { expect(product.product_type).to eq(:savings_fund) }
  it { expect(product.active).to be true }
  it { expect(product.description).to eq('Fondo de ahorro con rendimiento por tramos') }

  it 'defines the three balance tiers (CA3)' do
    expect(product.benefits).to contain_exactly(
      hash_including(tier: 1, rate: 12.0, max_balance: 25_000.0,
                     requirement: 'Ingresar o recibir al menos $3,000 mensuales'),
      hash_including(tier: 2, rate: 6.0, min_balance: 25_001.0, max_balance: 35_000.0, requirement: nil),
      hash_including(tier: 3, rate: 0.0, min_balance: 35_001.0, requirement: nil)
    )
  end
end
