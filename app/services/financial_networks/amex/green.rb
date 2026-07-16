# frozen_string_literal: true

module FinancialNetworks
  class Amex
    # Nivel Amex Green.
    class Green < BaseLevel
      def self.name
        'Amex Green'
      end

      def self.benefits
        [
          'Membership Rewards sin vencimiento',
          'Seguro de compra protegida'
        ]
      end
    end
  end
end
