# frozen_string_literal: true

module FinancialCatalogServices
  # Registry central de productos financieros definidos en codigo.
  class Catalog
    def self.all_products
      [
        Nu::NuCreditCard.new,
        Nu::NuFrozenSavings90.new,
        Klar::KlarDebitCard.new,
        Bbva::BbvaSavingsFund.new
      ].select(&:active)
    end
  end
end
