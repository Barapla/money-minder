# frozen_string_literal: true

FINANCIAL_PRODUCTS_SEED_DATA = {
  'Nu' => [
    { name: 'Nu Credito', product_type: :credit },
    { name: 'Nu Debito', product_type: :debit },
    { name: 'Cajita Turbo', product_type: :savings_fund }
  ],
  'BBVA' => [
    { name: 'BBVA Azul', product_type: :debit },
    { name: 'Oro', product_type: :credit },
    { name: 'Ahorro Digital', product_type: :savings_fund }
  ],
  'Klar' => [
    { name: 'Klar Debito', product_type: :debit },
    { name: 'Pesos MXN', product_type: :cash }
  ]
}.freeze

def seed_products_for(institution, products)
  products.each do |attrs|
    product = institution.financial_products.find_or_initialize_by(name: attrs[:name])
    product.assign_attributes(attrs)
    if product.save
      puts "  [OK] #{institution.name} - #{attrs[:name]} (#{attrs[:product_type]})"
    else
      puts "  [ERROR] #{institution.name} - #{attrs[:name]}: #{product.errors.full_messages.join(', ')}"
    end
  end
end

namespace :seed do
  desc 'Carga ejemplos de productos financieros para instituciones existentes'
  task financial_products: :environment do
    puts "\n=== Iniciando seed de productos financieros ==="

    FINANCIAL_PRODUCTS_SEED_DATA.each do |name, products|
      institution = FinancialInstitution.find_by(name:)
      puts("  Institución '#{name}' no encontrada, omitiendo") && next unless institution

      seed_products_for(institution, products)
    end

    puts "=== Seed de productos financieros completado ===\n"
  end
end
