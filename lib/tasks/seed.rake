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

  desc 'Carga datos de categorías desde categories.json'
  task categories: :environment do
    puts "\n=== Iniciando seed de categorías ===".cyan
    Seeds::CategoriesSeeder.create_categories
    puts "=== Seed de categorías completado ===\n".cyan
  end

  desc 'Carga datos de catalogos especificos desde catalogs.json'
  task :catalogs, [:catalog_name] => :environment do |t, args|
    puts "\n=== Iniciando seed de catalogos ===".cyan

    # Puedes acceder al argumento con args[:catalog_name]
    catalog_name = args[:catalog_name]

    if catalog_name
      puts "Cargando catálogo específico: #{catalog_name}".yellow
      Seeds::CatalogsSeeder.create_catalogs(catalog_name)
    else
      puts "Cargando todos los catálogos".yellow
      Seeds::CatalogsSeeder.create_catalogs
    end

    puts "=== Seed de catalogos completado ===\n".cyan
  end
end
