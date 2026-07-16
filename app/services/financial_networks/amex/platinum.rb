# frozen_string_literal: true

module FinancialNetworks
  class Amex
    # Nivel Amex Platinum.
    class Platinum < BaseLevel
      def self.name
        'Amex Platinum'
      end

      def self.benefits
        [
          'Acceso ilimitado a Centurion Lounge',
          'Membresia Global Lounge Collection',
          'Credito anual de viaje'
        ]
      end
    end
  end
end
