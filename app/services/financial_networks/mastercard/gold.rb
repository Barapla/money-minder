# frozen_string_literal: true

module FinancialNetworks
  class Mastercard
    # Nivel Mastercard Gold.
    class Gold < BaseLevel
      def self.name
        'Mastercard Gold'
      end

      def self.benefits
        [
          'Priceless Cities con beneficios ampliados',
          'Seguro de proteccion de precio'
        ]
      end
    end
  end
end
