# frozen_string_literal: true

module FinancialNetworks
  class Visa
    # Nivel Visa Signature.
    class Signature < BaseLevel
      def self.name
        'Visa Signature'
      end

      def self.benefits
        [
          'Visa Signature Concierge ilimitado',
          'Descuentos en experiencias gastronomicas seleccionadas',
          'Seguro medico en el extranjero'
        ]
      end
    end
  end
end
