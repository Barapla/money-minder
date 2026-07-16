# frozen_string_literal: true

module FinancialCatalogServices
  module MercadoPago
    # Cuenta Mercado Pago: fondo de ahorro con rendimiento escalonado por tramos de saldo (FEAT-025).
    class MercadoPagoCuenta < BaseProduct
      # Tramos de rendimiento anual segun saldo (CA3).
      BALANCE_TIERS = [
        { tier: 1, rate: 12.0, max_balance: 25_000.0, currency: 'MXN',
          requirement: 'Ingresar o recibir al menos $3,000 mensuales' },
        { tier: 2, rate: 6.0, min_balance: 25_001.0, max_balance: 35_000.0, currency: 'MXN', requirement: nil },
        { tier: 3, rate: 0.0, min_balance: 35_001.0, currency: 'MXN', requirement: nil }
      ].freeze

      def initialize
        super(
          name: 'Mercado Pago',
          institution: 'Mercado Pago',
          product_type: :savings_fund,
          benefits: BALANCE_TIERS
        )
      end

      # @return [String] descripcion visible en el catalogo
      def description
        'Fondo de ahorro con rendimiento por tramos'
      end
    end
  end
end
