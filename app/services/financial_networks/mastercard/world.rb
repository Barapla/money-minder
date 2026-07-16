# frozen_string_literal: true

module FinancialNetworks
  class Mastercard
    # Nivel Mastercard World.
    class World < BaseLevel
      def self.name
        'Mastercard World'
      end

      def self.benefits
        [
          'Mastercard Airport Experiences ilimitado',
          'Concierge World 24/7',
          'Seguro de renta de auto incluido'
        ]
      end
    end
  end
end
