# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreditCardCycle, type: :model do
  # `statement_balance` y `payments_after_cut` se derivan de las transacciones ligadas
  # al ciclo; aqui se fijan directo para probar cada rama del comportamiento de pago.
  def cycle(statement:, paid_after_cut: 0, purchases: statement, payments: paid_after_cut, minimum: 0)
    described_class.new(purchases:, payments:, minimum_payment: minimum).tap do |record|
      allow(record).to receive_messages(statement_balance: statement, payments_after_cut: paid_after_cut)
    end
  end

  describe '#estimated_minimum_payment' do
    it 'estima el 5% de la deuda cortada' do
      expect(cycle(statement: 3_326.62).estimated_minimum_payment).to eq(166.33)
    end

    it 'respeta el piso de $25 en cortes pequeños' do
      expect(cycle(statement: 100).estimated_minimum_payment).to eq(25.0)
    end

    it 'usa el mínimo ya persistido cuando el ciclo se cerró' do
      expect(cycle(statement: 3_326.62, minimum: 400).estimated_minimum_payment).to eq(400)
    end

    it 'es cero sin deuda al corte' do
      expect(cycle(statement: 0).estimated_minimum_payment).to eq(0.0)
    end
  end

  describe '#payment_behavior' do
    it 'reporta sin actividad cuando no hubo compras ni pagos' do
      expect(cycle(statement: 0, purchases: 0, payments: 0).payment_behavior).to eq('no_activity')
    end

    it 'reporta sin pago cuando hubo corte y ningún pago en la ventana' do
      expect(cycle(statement: 3_326.62).payment_behavior).to eq('no_payment')
    end

    it 'reporta menos del mínimo cuando el pago no alcanza el mínimo estimado' do
      expect(cycle(statement: 3_326.62, paid_after_cut: 50).payment_behavior).to eq('below_minimum')
    end

    it 'reporta pago mínimo cuando cubre el mínimo pero no el corte' do
      expect(cycle(statement: 3_326.62, paid_after_cut: 200).payment_behavior).to eq('minimum_payment')
    end

    it 'reporta pagado cuando los pagos cubren el corte completo' do
      expect(cycle(statement: 2_949.26, paid_after_cut: 2_949.26).payment_behavior).to eq('full_payment')
    end

    it 'reporta pagado cuando los pagos previos al corte dejaron la deuda en cero' do
      expect(cycle(statement: 0, purchases: 2_000, payments: 2_000).payment_behavior).to eq('full_payment')
    end
  end

  describe '#lifecycle_status_code' do
    def dated_cycle(cutting_date:, due_date:, paid: false)
      described_class.new(cutting_date:, payment_due_date: due_date).tap do |record|
        allow(record).to receive(:fully_paid?).and_return(paid)
      end
    end

    it 'está corriendo mientras no llega el corte' do
      entry = dated_cycle(cutting_date: Date.current + 5, due_date: Date.current + 15)
      expect(entry.lifecycle_status_code).to eq('open')
    end

    it 'está por pagar entre el corte y la fecha límite' do
      entry = dated_cycle(cutting_date: Date.current - 2, due_date: Date.current + 8)
      expect(entry.lifecycle_status_code).to eq('pending_payment')
    end

    it 'queda pagado si venció la fecha límite y se liquidó' do
      entry = dated_cycle(cutting_date: Date.current - 40, due_date: Date.current - 30, paid: true)
      expect(entry.lifecycle_status_code).to eq('closed')
    end

    it 'queda vencido si pasó la fecha límite sin liquidar' do
      entry = dated_cycle(cutting_date: Date.current - 40, due_date: Date.current - 30, paid: false)
      expect(entry.lifecycle_status_code).to eq('overdue')
    end
  end
end
