# frozen_string_literal: true

begin
  raw = YAML.load_file(Rails.root.join('config/payroll_constants.yml'), aliases: true)
  env_data = raw&.dig(Rails.env)
  raise "Configuración de nómina no encontrada para el entorno '#{Rails.env}'" unless env_data

  PayrollConstants = env_data.deep_symbolize_keys.freeze
rescue Errno::ENOENT => e
  raise "No se puede cargar config/payroll_constants.yml: #{e.message}"
rescue Psych::SyntaxError => e
  raise "YAML inválido en config/payroll_constants.yml: #{e.message}"
end

missing_keys = %i[uma_daily aguinaldo_days imss_worker_rate isr_table] - PayrollConstants.keys
raise "PayrollConstants le faltan claves requeridas: #{missing_keys.join(', ')}" if missing_keys.any?

raise 'PayrollConstants[:isr_table] debe ser un arreglo' unless PayrollConstants[:isr_table].is_a?(Array)
