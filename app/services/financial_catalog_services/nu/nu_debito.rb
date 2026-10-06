# frozen_string_literal: true

module FinancialCatalogServices
  module Nu
    # Tarjeta de debito Nu: identidad base del ecosistema, sin beneficios de tasa propios (FEAT-028).
    class NuDebito < BaseProduct
      def initialize
        super(
          name: 'Nu Debito',
          institution: 'Nu',
          product_type: :debit,
          benefits: []
        )
      end
    end
  end
end
