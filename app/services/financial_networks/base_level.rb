# frozen_string_literal: true

module FinancialNetworks
  # Clase base para niveles de tarjetas de credito dentro de una red (ej. Visa::Gold).
  # `id` y `network_id` se derivan del nombre real de la clase (no de `name`, que las
  # subclases sobreescriben con un texto de despliegue como "Visa Gold") para mantener
  # IDs estables independientemente del texto mostrado al usuario (FEAT-023).
  #
  # @example
  #   FinancialNetworks::Visa::Gold.id #=> "visa_gold"
  #   FinancialNetworks::Mastercard::WorldElite.id #=> "mastercard_world_elite"
  class BaseLevel
    def self.id
      raise NotImplementedError, 'BaseLevel must be subclassed' if self == BaseLevel

      "#{network_id}_#{to_s.demodulize.underscore}"
    end

    def self.network_id
      to_s.deconstantize.demodulize.underscore
    end

    def self.name
      raise NotImplementedError
    end

    def self.benefits
      []
    end
  end
end
