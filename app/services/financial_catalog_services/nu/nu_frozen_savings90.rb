# frozen_string_literal: true

module FinancialCatalogServices
  module Nu
    # Ahorro Congelado Nu a 90 dias: capital bloqueado con rendimiento diario compuesto.
    class NuFrozenSavings90 < BaseProduct
      ACCRUAL_FREQUENCY = :daily

      def initialize
        super(
          name: 'Congelado 90 dias',
          institution: 'Nu',
          product_type: :term_saving,
          benefits: [
            { type: :annual_yield, unit: :percentage, value: 12.0, description: '12% anual, retiro bloqueado' }
          ]
        )
      end
    end
  end
end
