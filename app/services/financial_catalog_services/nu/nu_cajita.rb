# frozen_string_literal: true

module FinancialCatalogServices
  module Nu
    # Fondo de ahorro liquido Nu: rendimiento diario, sin requisitos, liquidez 24/7 (FEAT-028).
    # Hasta 10 cajitas (Cajita + Cajita Turbo) simultaneas por usuario.
    class NuCajita < BaseProduct
      ACCRUAL_FREQUENCY = :daily

      def initialize
        super(
          name: 'Nu Cajita',
          institution: 'Nu',
          product_type: :savings_fund,
          benefits: [
            { type: :annual_yield, unit: :percentage, value: 6.50,
              description: 'Liquidez 24/7, sin requisitos. Hasta 10 cajitas simultaneas por usuario.' }
          ]
        )
      end
    end
  end
end
