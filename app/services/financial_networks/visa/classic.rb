# frozen_string_literal: true

module FinancialNetworks
  class Visa
    # Nivel Visa Classic.
    class Classic < BaseLevel
      def self.name
        'Visa Classic'
      end

      def self.benefits
        [
          'Sin anualidad el primer año',
          'Aceptacion en mas de 200 paises'
        ]
      end
    end
  end
end
