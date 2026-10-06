# frozen_string_literal: true

namespace :i18n do
  desc 'Check for hardcoded Spanish strings in ERB views and models'
  task health_check: :environment do
    puts "Analizando archivos en busca de strings hardcodeados en español...\n\n"

    # Patterns that indicate a hardcoded Spanish string
    SPANISH_WORD_PATTERN = /[áéíóúüñÁÉÍÓÚÜÑ]/.freeze
    # Exclude: YAML locale files, migration files, spec files, comments
    SKIP_DIRS = %w[config/locales db/migrate spec].freeze

    issues = []

    Dir.glob('app/views/**/*.erb').sort.each do |file|
      next if SKIP_DIRS.any? { |d| file.start_with?(d) }

      File.readlines(file).each_with_index do |line, idx|
        # Skip lines that are already using t() or I18n.t()
        next if line.match?(/\bt\(|I18n\.t\(/)
        # Skip HTML comments
        next if line.strip.start_with?('<%#', '<!--')
        # Flag lines with Spanish characters in quoted strings or plain text
        next unless line.match?(SPANISH_WORD_PATTERN)

        issues << { file: file, line: idx + 1, content: line.strip }
      end
    end

    if issues.empty?
      puts "OK: No se encontraron strings hardcodeados en espanol en las vistas."
      puts "Total de archivos analizados: #{Dir.glob('app/views/**/*.erb').size}"
    else
      puts "ADVERTENCIA: Se encontraron #{issues.size} posibles strings hardcodeados:\n\n"
      issues.each do |issue|
        puts "  #{issue[:file]}:#{issue[:line]}"
        puts "    #{issue[:content][0..120]}"
        puts
      end
      puts "\nTotal de problemas encontrados: #{issues.size}"
      exit 1
    end
  end
end
