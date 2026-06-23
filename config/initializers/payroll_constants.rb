# frozen_string_literal: true

# Constantes y valores de configuracion para calculos de nomina.
# Constantes del modulo (acceso directo): PayrollConstants::DEFAULT_ISR_RATE
# Valores del YAML via []: PayrollConstants[:uma_daily], PayrollConstants[:aguinaldo_days]
# Claves validas del YAML: :uma_daily, :aguinaldo_days
module PayrollConstants
  DEFAULT_ISR_RATE = 18.6
  DEFAULT_IMSS_RATE = 3.0
  DEFAULT_SAVINGS_FUND_RATE = 4.0

  YAML_CONFIG = begin
    raw = YAML.load_file(Rails.root.join('config/payroll_constants.yml'), aliases: true)
    env_data = raw&.dig(Rails.env)
    raise "Configuracion de nomina no encontrada para el entorno '#{Rails.env}'" unless env_data

    env_data.deep_symbolize_keys.freeze
  rescue Errno::ENOENT => e
    raise "No se puede cargar config/payroll_constants.yml: #{e.message}"
  rescue Psych::SyntaxError => e
    raise "YAML invalido en config/payroll_constants.yml: #{e.message}"
  end

  def self.[](key)
    YAML_CONFIG[key]
  end
end

missing_keys = %i[uma_daily aguinaldo_days] - PayrollConstants::YAML_CONFIG.keys
raise "PayrollConstants le faltan claves requeridas: #{missing_keys.join(', ')}" if missing_keys.any?
