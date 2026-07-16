# frozen_string_literal: true

module FinancialCatalogServices
  module Bbva
    # Fondo de ahorro digital BBVA.
    class BbvaSavingsFund < BaseProduct
      def initialize
        super(
          name: 'Ahorro Digital',
          institution: 'BBVA',
          product_type: :savings_fund,
          benefits: [
            { type: :annual_yield, unit: :percentage, value: 8.5, description: '8.5% de rendimiento anual' }
          ]
        )
      end
    end
  end
end
