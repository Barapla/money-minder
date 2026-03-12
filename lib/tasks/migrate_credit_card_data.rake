# frozen_string_literal: true

# lib/tasks/migrate_credit_card_data.rake
namespace :credit_cards do
  desc 'Migrar datos existentes de credit_cards a credit_card_cycles'
  task migrate_to_cycles: :environment do
    puts '🚀 Iniciando migración de datos de tarjetas de crédito...'
    CreditCard.all.each do |card|
      update_cycles_for_each_transaction(card)
      puts "✅ Tarjeta #{card.id} migrada correctamente"
    rescue StandardError => e
      puts "❌ Error en tarjeta #{card.id}: #{e.message}"
    end
  end

  private

  def update_cycles_for_each_transaction(card)
    transactions = card.transactions.order(transaction_date: :asc)

    transactions.each do |tx|
      # Solo usar CycleAssignment, crear ciclo vacío si no existe
      cutting_date = card.determine_cycle_cutting_date_for_transaction(tx)
      cycle = card.credit_card_cycles.find_or_create_by(cutting_date:) do |c|
        c.payment_due_date = cutting_date + card.payment_due_days.days
        c.cycle_balance = 0
        c.historical_balance = 0
        c.closing_balance = 0
        c.purchases = 0
        c.payments = 0
        c.status = Status.find_by(code: 'open')
      end
      previous_cycle = cycle.previous_cycle
      cycle.historical_balance = previous_cycle ? previous_cycle.closing_balance : card.initial_debt
      cycle.save!

      # Procesar la transacción individual
      cycle.process_transaction(tx)
    end
  end
end
