# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObligatoryPayment, type: :model do
  def create_recurring_payment(**attrs)
    payment = build(:obligatory_payment, due_date: nil, **attrs)
    payment.build_recurrence(
      frequency_type: create(:catalog),
      recurrenceable_type_catalog: create(:catalog),
      frequency_value: 1,
      start_date: Date.current
    )
    payment.save!
    payment
  end

  describe 'reminder_type' do
    it 'defaults to payment' do
      expect(build(:obligatory_payment).reminder_type).to eq('payment')
    end

    it 'permite payment e income' do
      expect(build(:obligatory_payment, reminder_type: 'income')).to be_income
      expect(build(:obligatory_payment, reminder_type: 'payment')).to be_payment
    end

    it 'rechaza valores fuera del enum' do
      expect { build(:obligatory_payment, reminder_type: 'refund') }.to raise_error(ArgumentError)
    end
  end

  describe 'due_date' do
    it 'es requerido cuando no hay recurrencia (recordatorio unico)' do
      payment = build(:obligatory_payment, due_date: nil)

      expect(payment).not_to be_valid
      expect(payment.errors[:due_date]).to be_present
    end

    it 'no es requerido cuando hay recurrencia' do
      payment = create_recurring_payment

      expect(payment.reload).to be_valid
    end

    it 'es valido con due_date presente y sin recurrencia' do
      payment = build(:obligatory_payment, due_date: Date.tomorrow)

      expect(payment).to be_valid
    end
  end

  describe '#one_time? / #recurring?' do
    it 'es one_time cuando no tiene recurrence' do
      payment = create(:obligatory_payment, due_date: Date.tomorrow)

      expect(payment).to be_one_time
      expect(payment).not_to be_recurring
    end

    it 'es recurring cuando tiene recurrence' do
      payment = create_recurring_payment

      expect(payment.reload).to be_recurring
      expect(payment.reload).not_to be_one_time
    end
  end

  describe 'scopes' do
    let!(:payment_reminder) { create(:obligatory_payment, reminder_type: 'payment', due_date: Date.tomorrow) }
    let!(:income_reminder) { create(:obligatory_payment, reminder_type: 'income', due_date: Date.tomorrow) }
    let!(:recurring_reminder) { create_recurring_payment(reminder_type: 'payment') }

    describe '.by_type' do
      it 'filtra por reminder_type' do
        expect(described_class.by_type('income')).to contain_exactly(income_reminder)
      end

      it 'retorna todos cuando el tipo esta en blanco' do
        expect(described_class.by_type(nil)).to contain_exactly(payment_reminder, income_reminder, recurring_reminder)
      end
    end

    describe '.one_time' do
      it 'retorna solo los que no tienen recurrence' do
        expect(described_class.one_time).to contain_exactly(payment_reminder, income_reminder)
      end
    end

    describe '.recurring' do
      it 'retorna solo los que tienen recurrence' do
        expect(described_class.recurring).to contain_exactly(recurring_reminder)
      end
    end
  end
end
