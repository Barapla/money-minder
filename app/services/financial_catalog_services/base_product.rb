# frozen_string_literal: true

module FinancialCatalogServices
  # Clase base para productos financieros definidos en codigo (FEAT-020).
  # Cada institucion implementa subclases concretas (ver Nu::NuCreditCard, Klar::KlarDebitCard, etc).
  class BaseProduct
    attr_reader :name, :institution, :product_type, :active, :benefits

    def initialize(name:, institution:, product_type:, active: true, benefits: [])
      @name = name
      @institution = institution
      @product_type = product_type
      @active = active
      @benefits = benefits
    end
  end
end
