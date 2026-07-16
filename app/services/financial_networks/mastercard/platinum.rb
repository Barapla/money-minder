# frozen_string_literal: true

module FinancialNetworks
  class Mastercard
    # Nivel Mastercard Platinum.
    class Platinum < BaseLevel
      def self.name
        'Mastercard Platinum'
      end

      def self.benefits
        [
          'Acceso a Mastercard Airport Experiences (2 visitas/año)',
          'Seguro de viaje internacional',
          'Asistencia medica en el extranjero'
        ]
      end
    end
  end
end
