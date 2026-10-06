# frozen_string_literal: true

module FinancialNetworks
  class Visa
    # Nivel Visa Infinite.
    class Infinite < BaseLevel
      def self.name
        'Visa Infinite'
      end

      def self.benefits
        [
          'Acceso ilimitado a salas Visa Infinite Lounge',
          'Membresia Priority Pass incluida',
          'Seguro de viaje premium con cobertura ampliada'
        ]
      end
    end
  end
end
