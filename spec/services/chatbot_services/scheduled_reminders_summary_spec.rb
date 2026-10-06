# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::ScheduledRemindersSummary, type: :service do
  let(:user) { create(:user) }

  it 'suma los recordatorios de tipo income y payment que caen dentro del rango' do
    make_obligatory_payment(user:, amount: 5000, reminder_type: 'income',
                            due_date: Date.current.beginning_of_month + 2.days)
    make_obligatory_payment(user:, amount: 1200, reminder_type: 'payment',
                            due_date: Date.current.beginning_of_month + 5.days)
    make_obligatory_payment(user:, amount: 9999, reminder_type: 'payment',
                            due_date: Date.current.end_of_month + 10.days)

    summary = described_class.new(user)

    expect(summary.scheduled_income_total).to eq(5000.0)
    expect(summary.scheduled_payment_total).to eq(1200.0)
  end

  # El rango se ancla a la fecha en que arranca la recurrencia (make_obligatory_payment
  # la crea con start_date = hoy), NO al inicio del mes. Anclarlo al mes hacia que
  # el resultado dependiera del dia en que corrieran las pruebas: del 1 al 21
  # cabian varias ocurrencias, del 22 en adelante solo una y fallaba.
  describe 'recordatorio recurrente' do
    before do
      make_obligatory_payment(user:, amount: 100, reminder_type: 'payment', recurring: true,
                              frequency_code: 'weekly', frequency_value: 1)
    end

    it 'cuenta cada ocurrencia dentro del rango, no el recordatorio una sola vez' do
      summary = described_class.new(user, from_date: Date.current, to_date: Date.current + 27.days)

      # Semanal desde hoy: hoy, +7, +14, +21. La de +28 queda fuera.
      expect(summary.scheduled_payment_total).to eq(400.0)
    end

    it 'cuenta una sola vez cuando el rango no alcanza la siguiente ocurrencia' do
      summary = described_class.new(user, from_date: Date.current, to_date: Date.current + 6.days)

      expect(summary.scheduled_payment_total).to eq(100.0)
    end

    it 'no cuenta nada cuando el rango termina antes de que arranque' do
      summary = described_class.new(user, from_date: Date.current - 30.days,
                                          to_date: Date.current - 1.day)

      expect(summary.scheduled_payment_total).to eq(0.0)
    end
  end
end
