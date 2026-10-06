# frozen_string_literal: true

module FinancialCatalogServices
  module MercadoPago
    # Tarjeta de credito Mercado Pago: nivel Visa Classic, sin anualidad ni cashback propio (FEAT-025).
    # Las promociones rotativas de este producto no se modelan (fuera de alcance).
    class MercadoPagoTarjetaCredito < BaseProduct
      def initialize
        super(
          name: 'Tarjeta de crédito Mercado Pago',
          institution: 'Mercado Pago',
          product_type: :credit,
          benefits: []
        )
      end

      # @return [String] descripcion visible en el catalogo
      def description
        'Tarjeta Visa Classic sin anualidad ni cashback'
      end

      def network_level
        FinancialNetworks::Visa::Classic
      end
    end
  end
end
