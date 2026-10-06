# frozen_string_literal: true

module FinancialNetworks
  class Visa
    # Nivel Visa Gold.
    class Gold < BaseLevel
      def self.name
        'Visa Gold'
      end

      def self.benefits
        [
          'Proteccion de compras hasta 90 dias',
          'Seguro de viaje internacional',
          'Asistencia en carretera 24/7'
        ]
      end
    end
  end
end
