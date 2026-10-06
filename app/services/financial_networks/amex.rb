# frozen_string_literal: true

module FinancialNetworks
  # Red American Express. Jerarquia independiente de Visa y Mastercard: sus niveles
  # (Green, Gold, Platinum, Centurion) tienen beneficios propios, no comparables
  # entre redes aunque compartan nombre de nivel (ej. Amex Gold vs Visa Gold) (FEAT-023).
  class Amex < BaseNetwork
    def self.name
      'American Express'
    end

    def self.all_levels
      [
        Amex::Green,
        Amex::Gold,
        Amex::Platinum,
        Amex::Centurion
      ]
    end
  end
end
