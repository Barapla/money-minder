# frozen_string_literal: true

BENEFIT_REQUIREMENTS_SEED_DATA = {
  'Nu' => {
    'Cajita Turbo' => {
      annual_yield: {
        requirements_logic: :all,
        requirements: [
          { requirement_type: :min_transactions, min_transactions_count: 1 }
        ]
      }
    }
  },
  'Revolut' => {
    'Revolut Standard' => {
      annual_yield: {
        requirements_logic: :any,
        requirements: [
          { requirement_type: :min_transactions_with_amount,
            min_transactions_count: 4,
            min_amount_per_transaction: 50.00 },
          { requirement_type: :monthly_fee, monthly_fee_amount: 179.00 }
        ]
      }
    }
  },
  'Mercado Pago' => {
    'Cuenta Mercado Pago' => {
      annual_yield: {
        requirements_logic: :all,
        requirements: [
          { requirement_type: :accumulated_amount, min_accumulated_amount: 2_500.00 }
        ]
      }
    }
  }
}.freeze

def save_requirement(benefit, attrs)
  req = benefit.requirements.find_or_initialize_by(requirement_type: attrs[:requirement_type])
  req.assign_attributes(attrs)
  key = attrs[:requirement_type]
  if req.save
    puts "      [OK] Requisito '#{key}' guardado"
  else
    puts "      [ERROR] Requisito '#{key}': #{req.errors.full_messages.join(', ')}"
  end
end

def seed_requirements_for(product, benefit_type_key, config)
  type_value = FinancialProductBenefit.benefit_types[benefit_type_key]
  benefit = product.benefits.find_by(benefit_type: type_value)
  return puts "    [OMITIDO] Beneficio '#{benefit_type_key}' no encontrado en #{product.name}" unless benefit

  benefit.update!(requirements_logic: config[:requirements_logic])
  config[:requirements].each { |attrs| save_requirement(benefit, attrs) }
end

def seed_requirements_for_institution(institution_name, products_map)
  institution = FinancialInstitution.find_by(name: institution_name)
  return puts "  Institucion '#{institution_name}' no encontrada, omitiendo" unless institution

  products_map.each do |product_name, benefits_map|
    product = institution.financial_products.find_by(name: product_name)
    next puts "  Producto '#{product_name}' no encontrado en #{institution_name}, omitiendo" unless product

    puts "  #{institution_name} - #{product_name}:"
    benefits_map.each { |bt, config| seed_requirements_for(product, bt, config) }
  end
end

namespace :db do
  namespace :seed do
    desc 'Carga requisitos de ejemplo para beneficios de productos financieros'
    task financial_product_benefit_requirements: :environment do
      puts "\n=== Iniciando seed de requisitos de beneficios ==="
      BENEFIT_REQUIREMENTS_SEED_DATA.each do |name, products|
        seed_requirements_for_institution(name, products)
      end
      puts "=== Seed de requisitos completado ===\n"
    end
  end
end
