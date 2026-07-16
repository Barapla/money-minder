# frozen_string_literal: true

module FinancialCatalogServices
  module Nu
    # Tarjeta de credito Nu.
    class NuCreditCard < BaseProduct
      def initialize
        super(
          name: 'Nu Credito',
          institution: 'Nu',
          product_type: :credit,
          benefits: [
            { type: :cashback, unit: :percentage, value: 3.0, description: '3% cashback en compras seleccionadas' }
          ]
        )
      end
    end
  end
end
