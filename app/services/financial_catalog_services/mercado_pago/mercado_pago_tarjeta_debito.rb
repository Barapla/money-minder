# frozen_string_literal: true

module FinancialCatalogServices
  module MercadoPago
    # Tarjeta de debito Mercado Pago: identidad de catalogo sobre red Mastercard, sin beneficios propios (FEAT-025).
    class MercadoPagoTarjetaDebito < BaseProduct
      def initialize
        super(
          name: 'Tarjeta de débito Mercado Pago',
          institution: 'Mercado Pago',
          product_type: :debit,
          benefits: []
        )
      end

      # @return [String] descripcion visible en el catalogo
      def description
        'Tarjeta Mastercard sin beneficios propios'
      end
    end
  end
end
