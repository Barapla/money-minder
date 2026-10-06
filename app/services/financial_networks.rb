# frozen_string_literal: true

# Jerarquia de redes (Visa, Mastercard, Amex) y niveles de tarjetas de credito,
# definida en codigo como componentes reutilizables e independientes de la
# institucion financiera emisora (FEAT-023).
#
# @example Consultar todas las redes
#   FinancialNetworks.all_networks #=> [FinancialNetworks::Visa, FinancialNetworks::Mastercard, FinancialNetworks::Amex]
#
# @example Buscar un nivel por su id estable
#   FinancialNetworks.find_level('visa_gold') #=> FinancialNetworks::Visa::Gold
module FinancialNetworks
  def self.all_networks
    [Visa, Mastercard, Amex]
  end

  def self.find_level(level_id)
    all_networks.flat_map(&:all_levels).find { |level| level.id == level_id }
  end
end
