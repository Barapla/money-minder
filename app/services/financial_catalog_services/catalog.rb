# frozen_string_literal: true

module FinancialCatalogServices
  # Registry central de productos financieros definidos en codigo.
  class Catalog
    def self.all_products # rubocop:disable Metrics/MethodLength
      [
        Nu::NuCreditCard.new,
        Nu::NuFrozenSavings90.new,
        Nu::NuDebito.new,
        Nu::NuCajita.new,
        Nu::NuCajitaTurbo.new,
        Nu::NuAhorroCongelado.new,
        Klar::KlarDebitCard.new,
        Bbva::BbvaSavingsFund.new,
        MercadoPago::MercadoPagoCuenta.new,
        MercadoPago::MercadoPagoTarjetaDebito.new,
        MercadoPago::MercadoPagoTarjetaCredito.new
      ].select(&:active)
    end
  end
end
