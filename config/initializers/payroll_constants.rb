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

isr_table = PayrollConstants[:isr_table]
required_bracket_keys = %i[lower_limit upper_limit fixed_quota rate]

isr_table.each_with_index do |bracket, idx|
  missing = required_bracket_keys.select { |k| bracket[k].nil? }
  raise "PayrollConstants[:isr_table][#{idx}] le faltan campos: #{missing.join(', ')}" if missing.any?

  non_numeric = required_bracket_keys.reject { |k| bracket[k].is_a?(Numeric) }
  raise "PayrollConstants[:isr_table][#{idx}] tiene campos no numéricos: #{non_numeric.join(', ')}" if non_numeric.any?

  unless bracket[:upper_limit] > bracket[:lower_limit]
    raise "PayrollConstants[:isr_table][#{idx}] inválido: upper_limit debe ser mayor que lower_limit"
  end
end

isr_table.sort_by { |b| b[:lower_limit] }.each_cons(2) do |prev, curr|
  next unless curr[:lower_limit] <= prev[:upper_limit]

  raise 'PayrollConstants[:isr_table] tiene tramos superpuestos: ' \
        "límite_superior=#{prev[:upper_limit]}, límite_inferior=#{curr[:lower_limit]}"
end
