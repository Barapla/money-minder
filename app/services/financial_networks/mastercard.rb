# frozen_string_literal: true

module FinancialNetworks
  # Red Mastercard. Agrupa los niveles Standard, Gold, Platinum, World y World Elite,
  # cuyos beneficios son compartidos por todas las tarjetas Mastercard del catalogo
  # sin importar la institucion emisora (FEAT-023).
  class Mastercard < BaseNetwork
    def self.name
      'Mastercard'
    end

    def self.all_levels
      [
        Mastercard::Standard,
        Mastercard::Gold,
        Mastercard::Platinum,
        Mastercard::World,
        Mastercard::WorldElite
      ]
    end
  end
end
