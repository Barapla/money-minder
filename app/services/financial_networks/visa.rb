# frozen_string_literal: true

module FinancialNetworks
  # Red Visa. Agrupa los niveles Classic, Gold, Platinum, Signature e Infinite,
  # cuyos beneficios son compartidos por todas las tarjetas Visa del catalogo
  # sin importar la institucion emisora (FEAT-023).
  class Visa < BaseNetwork
    def self.name
      'Visa'
    end

    def self.all_levels
      [
        Visa::Classic,
        Visa::Gold,
        Visa::Platinum,
        Visa::Signature,
        Visa::Infinite
      ]
    end
  end
end
