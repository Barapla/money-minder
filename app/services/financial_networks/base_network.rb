# frozen_string_literal: true

module FinancialNetworks
  # Clase base para redes de tarjetas de credito (Visa, Mastercard, Amex).
  # Cada red concreta hereda de esta clase y define su nombre y sus niveles (FEAT-023).
  #
  # @example
  #   FinancialNetworks::Visa.id #=> "visa"
  #   FinancialNetworks::Visa.all_levels #=> [FinancialNetworks::Visa::Classic, ...]
  class BaseNetwork
    def self.id
      to_s.demodulize.underscore
    end

    def self.name
      raise NotImplementedError
    end

    def self.all_levels
      raise NotImplementedError
    end
  end
end
