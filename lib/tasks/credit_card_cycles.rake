# frozen_string_literal: true

namespace :credit_card_cycles do
  desc 'Reasigna las transacciones a sus ciclos y recalcula saldos. ' \
       'Uso: rake credit_card_cycles:recalculate[budget_id] (sin id procesa todas las tarjetas)'
  task :recalculate, [:budget_id] => :environment do |_task, args|
    cards = CreditCardCycles::Recalculator.cards_for(args[:budget_id])
    abort 'No se encontraron tarjetas de credito para recalcular.' if cards.empty?

    cards.each do |card|
      result = CreditCardCycles::Recalculator.new(card).call
      puts "#{card.budget.name}: #{result[:transactions]} transacciones en #{result[:cycles]} ciclos"
      result[:cycles_detail].each { |line| puts "  #{line}" }
    end
  end
end
