# frozen_string_literal: true

module FinancialNetworks
  class Amex
    # Nivel Amex Centurion.
    class Centurion < BaseLevel
      def self.name
        'Amex Centurion'
      end

      def self.benefits
        [
          'Concierge personal Centurion 24/7',
          'Acceso a eventos exclusivos por invitacion',
          'Seguro de viaje sin limite de cobertura'
        ]
      end
    end
  end
end
