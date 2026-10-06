# frozen_string_literal: true

module FinancialCatalogServices
  # Clase base para productos financieros definidos en codigo (FEAT-020).
  # Cada institucion implementa subclases concretas (ver Nu::NuCreditCard, Klar::KlarDebitCard, etc).
  class BaseProduct
    # Frecuencia de devengo de rendimientos para productos de plazo fijo
    # (ver FinancialNetworks-style override: subclases redefinen esta constante).
    # Valores permitidos: :daily (interes compuesto diario) o :at_maturity
    # (interes simple liquidado al vencimiento). Ver TermSavingServices::AccruedInterestCalculator.
    ACCRUAL_FREQUENCY = :at_maturity
    ALLOWED_ACCRUAL_FREQUENCIES = %i[daily at_maturity].freeze

    attr_reader :id, :name, :institution, :product_type, :active, :benefits

    def initialize(name:, institution:, product_type:, active: true, benefits: [])
      @id = self.class.name.demodulize.underscore
      @name = name
      @institution = institution
      @product_type = product_type
      @active = active
      @benefits = benefits
    end

    # Red y nivel de tarjeta asociados a este producto (ver FinancialNetworks).
    # Productos sin red/nivel (ej. cash, savings_fund) retornan nil.
    #
    # @return [Class, nil] subclase de FinancialNetworks::BaseLevel, o nil
    def network_level
      nil
    end

    # @return [Symbol] :daily o :at_maturity
    def accrual_frequency
      self.class::ACCRUAL_FREQUENCY
    end
  end
end
