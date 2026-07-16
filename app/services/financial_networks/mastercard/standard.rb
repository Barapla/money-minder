# frozen_string_literal: true

module FinancialNetworks
  class Mastercard
    # Nivel Mastercard Standard.
    class Standard < BaseLevel
      def self.name
        'Mastercard Standard'
      end

      def self.benefits
        [
          'Cinepolis 2x1 (2 canjes/mes)',
          'Priceless Cities'
        ]
      end
    end
  end
end
