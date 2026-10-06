# frozen_string_literal: true

module FinancialCatalogServices
  module Klar
    # Tarjeta de debito Klar.
    class KlarDebitCard < BaseProduct
      def initialize
        super(
          name: 'Klar Debito',
          institution: 'Klar',
          product_type: :debit,
          benefits: [
            { type: :annual_yield, unit: :percentage, value: 15.0, amount_cap: 25_000.0,
              description: '15% de rendimiento hasta $25,000 MXN de saldo' }
          ]
        )
      end
    end
  end
end
