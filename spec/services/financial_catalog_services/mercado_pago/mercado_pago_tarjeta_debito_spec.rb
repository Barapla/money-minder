# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::MercadoPago::MercadoPagoTarjetaDebito do
  subject(:product) { described_class.new }

  it { expect(product).to be_a(FinancialCatalogServices::BaseProduct) }
  it { expect(product.id).to eq('mercado_pago_tarjeta_debito') }
  it { expect(product.name).to eq('Tarjeta de débito Mercado Pago') }
  it { expect(product.institution).to eq('Mercado Pago') }
  it { expect(product.product_type).to eq(:debit) }
  it { expect(product.active).to be true }
  it { expect(product.benefits).to eq([]) }

  it 'mentions Mastercard in its description (CA4)' do
    expect(product.description).to include('Mastercard')
  end
end
