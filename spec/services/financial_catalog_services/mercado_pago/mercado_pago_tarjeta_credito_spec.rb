# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::MercadoPago::MercadoPagoTarjetaCredito do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('mercado_pago_tarjeta_credito') }
  it { expect(product.name).to eq('Tarjeta de crédito Mercado Pago') }
  it { expect(product.institution).to eq('Mercado Pago') }
  it { expect(product.product_type).to eq(:credit) }
  it { expect(product.active).to be true }
  it { expect(product.benefits).to eq([]) }

  it 'has Visa Classic as its network_level (CA5)' do
    expect(product.network_level).to eq(FinancialNetworks::Visa::Classic)
  end
end
