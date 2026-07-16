# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialCatalogServices::Catalog do
  describe '.all_products' do
    subject(:products) { described_class.all_products }

    it 'returns an instance of every active product defined in code' do
      expect(products).to contain_exactly(
        an_instance_of(FinancialCatalogServices::Nu::NuCreditCard),
        an_instance_of(FinancialCatalogServices::Nu::NuFrozenSavings90),
        an_instance_of(FinancialCatalogServices::Klar::KlarDebitCard),
        an_instance_of(FinancialCatalogServices::Bbva::BbvaSavingsFund),
        an_instance_of(FinancialCatalogServices::MercadoPago::MercadoPagoCuenta),
        an_instance_of(FinancialCatalogServices::MercadoPago::MercadoPagoTarjetaDebito),
        an_instance_of(FinancialCatalogServices::MercadoPago::MercadoPagoTarjetaCredito)
      )
    end

    it 'only returns active products' do
      expect(products).to all(have_attributes(active: true))
    end
  end
end
