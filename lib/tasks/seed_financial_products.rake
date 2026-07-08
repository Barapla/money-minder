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

FINANCIAL_PRODUCT_BENEFITS_SEED_DATA = {
  'Nu' => {
    'Cajita Turbo' => [
      { benefit_type: :annual_yield, base_value: 13.0, reduced_value: 7.0,
        unit: :percentage, description: '13% rendimiento con requisitos, 7% sin cumplir' },
      { benefit_type: :cashback, base_value: 3.0, unit: :percentage,
        description: '3% cashback en compras seleccionadas' }
    ]
  },
  'BBVA' => {
    'Oro' => [
      { benefit_type: :cashback, base_value: 2.0, unit: :percentage,
        description: '2% cashback en todas las compras' },
      { benefit_type: :points, base_value: 1500.0, unit: :points,
        description: 'Bono de bienvenida de 1,500 puntos' }
    ]
  },
  'Klar' => {
    'Klar Debito' => [
      { benefit_type: :annual_yield, base_value: 15.0, amount_cap: 25_000.0,
        unit: :percentage, description: '15% hasta $25,000 MXN de saldo' }
    ]
  }
}.freeze

def save_benefit(product, attrs)
  benefit = product.benefits.find_or_initialize_by(benefit_type: attrs[:benefit_type], unit: attrs[:unit])
  benefit.assign_attributes(attrs)
  key = "#{attrs[:benefit_type]} (#{attrs[:unit]})"
  if benefit.save
    puts "    [OK] #{product.name} - #{key}"
  else
    puts "    [ERROR] #{product.name} - #{key}: #{benefit.errors.full_messages.join(', ')}"
  end
end

def seed_benefits_for(product, benefits)
  benefits.each { |attrs| save_benefit(product, attrs) }
end

def seed_product_benefits(institution_name, products_map)
  institution = FinancialInstitution.find_by(name: institution_name)
  return puts "  Institución '#{institution_name}' no encontrada, omitiendo" unless institution

  products_map.each do |product_name, benefits|
    product = institution.financial_products.find_by(name: product_name)
    next puts "  Producto '#{product_name}' no encontrado en #{institution_name}, omitiendo" unless product

    puts "  #{institution_name} - #{product_name}:"
    seed_benefits_for(product, benefits)
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

  desc 'Carga beneficios de ejemplo para productos financieros existentes'
  task financial_product_benefits: :environment do
    puts "\n=== Iniciando seed de beneficios de productos financieros ==="
    FINANCIAL_PRODUCT_BENEFITS_SEED_DATA.each { |name, products| seed_product_benefits(name, products) }
    puts "=== Seed de beneficios completado ===\n"
  end
end
