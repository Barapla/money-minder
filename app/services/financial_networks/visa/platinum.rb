# frozen_string_literal: true

module FinancialNetworks
  class Visa
    # Nivel Visa Platinum.
    class Platinum < BaseLevel
      def self.name
        'Visa Platinum'
      end

      def self.benefits
        [
          'Acceso a salas VIP en aeropuertos (4 visitas/año)',
          'Seguro de auto de renta incluido',
          'Concierge Visa Platinum 24/7'
        ]
      end
    end
  end
end
