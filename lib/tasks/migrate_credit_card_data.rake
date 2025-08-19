# lib/tasks/migrate_credit_card_data.rake

namespace :credit_cards do
  desc "Migrar datos existentes de credit_cards a credit_card_cycles"
  task migrate_to_cycles: :environment do
    puts "🚀 Iniciando migración de datos de tarjetas de crédito..."

    migrated_count = 0
    error_count = 0

    CreditCard.find_each do |card|
      begin
        # Actualizar los nuevos campos integer
        update_card_fields(card)

        # Crear ciclo con la deuda actual
        create_current_cycle(card) if card.debt_amount.present? && card.debt_amount > 0

        migrated_count += 1
        puts "✅ Tarjeta #{card.id} migrada correctamente"

      rescue StandardError => e
        error_count += 1
        puts "❌ Error en tarjeta #{card.id}: #{e.message}"
      end
    end

    puts "\n📊 Resumen de migración:"
    puts "   ✅ Tarjetas migradas: #{migrated_count}"
    puts "   ❌ Errores: #{error_count}"
    puts "   📅 Ciclos creados: #{CreditCardCycle.count}"
    puts "\n🎉 Migración completada!"
  end

  private

  def update_card_fields(card)
    # Convertir cutting_day (date) a cutting_day (integer)
    cutting_day_int = if card.cutting_day.present?
      card.cutting_day.day
    else
      15 # default
    end

    # Calcular payment_due_days
    payment_due_days = if card.payday.present? && card.cutting_day.present?
      calculate_days_between(card.cutting_day_int, card.payday)
    else
      5 # default
    end

    # Actualizar sin validaciones
    card.update_columns(
      cutting_day_int:,  # <-- CORRECCIÓN
      payment_due_days: payment_due_days
    )
    puts "   📋 Día corte: #{cutting_day_int}, Días pago: #{payment_due_days}"
  end

  def calculate_days_between(cutting_date, pay_date)
    # Si están en el mismo mes
    if cutting_date.month == pay_date.month && cutting_date.year == pay_date.year
      pay_date.day - cutting_date.day
    else
      # Si el pago es al siguiente mes
      days_to_month_end = cutting_date.end_of_month.day - cutting_date.day
      days_to_month_end + pay_date.day
    end.clamp(1, 31)
  rescue StandardError
    5 # default fallback
  end

  def create_current_cycle(card)
    debt = card.debt_amount

    # Determinar fechas del ciclo actual
    today = Date.current
    cutting_date = calculate_current_cutting_date(today, card.cutting_day_int)
    payment_due_date = cutting_date + card.payment_due_days.days

    cycle = CreditCardCycle.create!(
      credit_card: card,
      cutting_date: cutting_date,
      payment_due_date: payment_due_date,
      statement_balance: debt,
      current_balance: debt,
      minimum_payment: (debt * 0.05).clamp(25.0, debt),
      purchases_made: debt,
      payments_received: 0.0,
      status: Status.find_by(code: cutting_date <= today ? 'closed' : 'open')
    )

    puts "   💰 Ciclo creado: #{cutting_date} -> #{payment_due_date}, Balance: $#{debt}"
    cycle
  end

  def calculate_current_cutting_date(today, cutting_day_int)
    # Si ya pasó el corte de este mes, usar este mes
    # Si no, usar el mes anterior
    current_month_cutting = Date.new(today.year, today.month, cutting_day_int)

    if today >= current_month_cutting
      current_month_cutting
    else
      prev_month = today.beginning_of_month - 1.day
      Date.new(prev_month.year, prev_month.month, cutting_day_int)
    end
  rescue ArgumentError
    # Para casos como 31 de febrero
    Date.new(today.year, today.month, -1)
  end
end

# Task adicional para verificar los datos migrados
namespace :credit_cards do
  desc "Verificar datos migrados"
  task verify_migration: :environment do
    puts "🔍 Verificando migración..."
    puts "=" * 50

    CreditCard.includes(:credit_card_cycles).each do |card|
      puts "\n📋 Tarjeta #{card.id}:"
      puts "   Corte día: #{card.cutting_day_int }"
      puts "   Días pago: #{card.payment_due_days}"
      puts "   Deuda original: $#{card.debt_amount}"
      puts "   Ciclos: #{card.credit_card_cycles.count}"

      card.credit_card_cycles.each do |cycle|
        puts "      📅 #{cycle.cutting_date} -> #{cycle.payment_due_date} | $#{cycle.current_balance}"
      end
    end

    puts "\n" + "=" * 50
    puts "📊 Total: #{CreditCard.count} tarjetas, #{CreditCardCycle.count} ciclos"
  end
end
