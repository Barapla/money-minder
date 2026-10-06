# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditCardCycles::Recalculator do
  include FinancialTestHelpers
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:card) { make_credit_card(user:, limit_amount: 21_000, name: 'Klar', cutting_day: 17) }
  let(:budget) { card.budget }

  def expense(amount, on:)
    make_transaction(user:, budget:, category: category_for('Internet'), amount:,
                     type_code: 'expense', transaction_date: on)
  end

  def payment(amount, on:)
    make_transaction(user:, budget:, category: category_for('Internet'), amount:,
                     type_code: 'income', transaction_date: on)
  end

  def cycle_on(date)
    card.credit_card_cycles.find_by(cutting_date: date)
  end

  # Historial capturado con la regla vieja: el pago del 26/08 quedo en el ciclo
  # del 17/09 en vez del 17/08 que estaba en ventana de pago.
  def seed_history!
    card.update!(payment_due_days: 10)
    travel_to(Date.new(2026, 9, 19)) do
      expense(3_079.09, on: Date.new(2026, 7, 7))
      payment(3_079.09, on: Date.new(2026, 7, 21))
      expense(2_949.26, on: Date.new(2026, 8, 12))
      payment(2_949.26, on: Date.new(2026, 8, 26))
      expense(3_326.62, on: Date.new(2026, 9, 10))
    end
  end

  it 'reasigna el pago de la ventana al corte que le corresponde' do
    seed_history!
    travel_to(Date.new(2026, 9, 19)) { described_class.new(card).call }

    expect(cycle_on(Date.new(2026, 8, 17)).payments).to eq(2_949.26)
    expect(cycle_on(Date.new(2026, 9, 17)).payments).to eq(0)
  end

  it 'deja la deuda vigente igual que antes de recalcular' do
    seed_history!
    travel_to(Date.new(2026, 9, 19)) do
      described_class.new(card).call
      expect(card.reload.current_debt).to eq(3_326.62)
    end
  end

  it 'es idempotente' do
    seed_history!
    travel_to(Date.new(2026, 9, 19)) do
      described_class.new(card).call
      first = card.credit_card_cycles.order(:cutting_date).pluck(:purchases, :payments, :closing_balance)
      described_class.new(card).call
      second = card.credit_card_cycles.order(:cutting_date).pluck(:purchases, :payments, :closing_balance)
      expect(second).to eq(first)
    end
  end

  it 'no duplica las ligas de transacciones a ciclos' do
    seed_history!
    travel_to(Date.new(2026, 9, 19)) do
      described_class.new(card).call
      described_class.new(card).call
    end

    links = CreditCardCycleTransaction.where(credit_card_cycle: card.credit_card_cycles).count
    expect(links).to eq(5)
  end

  it 'conserva la deuda arrastrada por los ciclos que quedan sin transacciones' do
    # La tarjeta nace en junio con deuda inicial y no se mueve hasta septiembre:
    # los ciclos intermedios van vacios y aun asi tienen que arrastrar el saldo.
    travel_to(Date.new(2026, 6, 1)) { card.update!(initial_debt: 5_092.14, payment_due_days: 10) }
    travel_to(Date.new(2026, 9, 19)) do
      expense(250.80, on: Date.new(2026, 9, 9))
      described_class.new(card).call

      empties = card.credit_card_cycles.reload.order(:cutting_date)
                    .select { |cycle| cycle.purchases.to_f.zero? && cycle.payments.to_f.zero? }
      expect(empties).to be_any
      empties.each { |cycle| expect(cycle.closing_balance).to eq(cycle.historical_balance) }
      expect(card.reload.current_debt).to eq(5_342.94)
    end
  end

  describe '.cards_for' do
    it 'filtra por budget cuando se pasa un id' do
      expect(described_class.cards_for(budget.id).to_a).to eq([card])
    end

    it 'trae todas las tarjetas sin id' do
      card
      expect(described_class.cards_for(nil).count).to eq(1)
    end
  end
end
