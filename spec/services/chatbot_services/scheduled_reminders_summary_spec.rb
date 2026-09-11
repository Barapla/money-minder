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

  it 'cuenta cada ocurrencia de un recordatorio recurrente dentro del rango' do
    make_obligatory_payment(user:, amount: 100, reminder_type: 'payment', recurring: true,
                            frequency_code: 'weekly', frequency_value: 1)

    summary = described_class.new(user, from_date: Date.current.beginning_of_month,
                                        to_date: Date.current.beginning_of_month + 27.days)

    expect(summary.scheduled_payment_total).to be > 100
  end
end
