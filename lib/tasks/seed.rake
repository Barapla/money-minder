# frozen_string_literal: true

# lib/tasks/seed.rake
namespace :seed do
  desc 'Carga datos desde archivos JSON dinámicamente'
  task dynamic: :environment do
    # Orden de los archivos basado en dependencias
    seed_files = Dir[Rails.root.join('db/seeds/*.json')]

    seed_files.each do |filename|
      puts "\n=== Procesando #{filename} ===".cyan
      Seeds::DynamicSeeder.seed_from_json(filename)
    end
  end
end
