# frozen_string_literal: true

# lib/tasks/seed_helpers/base_seeder.rb
module Seeds
  # La clase base que proporciona funcionalidad común para todos los seeders
  class BaseSeeder
    # Métodos de clase
    class << self
      protected

      # Carga y parsea un archivo JSON
      def load_json(filename)
        file_path = Rails.root.join('db', 'seeds', filename)
        JSON.parse(File.read(file_path))
      end

      # Registra mensajes de progreso
      def log_progress(message)
        Rails.logger.info("[SEED] #{message}")
        puts "[SEED] #{message}" unless Rails.env.test?
      end

      # Manejo de transacciones y errores
      def handle_errors(&block)
        ActiveRecord::Base.transaction(&block)
      rescue StandardError => e
        log_progress("Error: #{e.message}")
        raise e
      end
    end
  end
end
