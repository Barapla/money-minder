# frozen_string_literal: true

module FinancialNetworks
  class Mastercard
    # Nivel Mastercard World Elite.
    class WorldElite < BaseLevel
      def self.name
        'Mastercard World Elite'
      end

      def self.benefits
        [
          'Acceso ilimitado a Lounge Key',
          'Concierge World Elite premium',
          'Seguro de viaje con cobertura maxima'
        ]
      end
    end
  end
end
