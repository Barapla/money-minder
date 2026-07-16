# frozen_string_literal: true

module FinancialNetworks
  class Amex
    # Nivel Amex Gold.
    class Gold < BaseLevel
      def self.name
        'Amex Gold'
      end

      def self.benefits
        [
          'Puntos dobles en restaurantes',
          'Credito anual en experiencias gastronomicas',
          'Seguro de auto de renta incluido'
        ]
      end
    end
  end
end
