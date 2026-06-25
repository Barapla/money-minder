# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PayrollReminder, type: :model do
  let(:breakdown) { { base_salary: 30_000, net_salary: 30_000 } }

  def build_reminder(payment_frequency)
    described_class.new(
      date: Date.current + 7,
      net_amount: 15_000,
      calculation_breakdown: breakdown,
      payment_frequency: payment_frequency
    )
  end

  describe '#periodicity_label' do
    it 'retorna etiqueta para weekly' do
      expect(build_reminder('weekly').periodicity_label).to eq('Pago semanal')
    end

    it 'retorna etiqueta para biweekly' do
      expect(build_reminder('biweekly').periodicity_label).to eq('Quincena')
    end

    it 'retorna etiqueta para monthly' do
      expect(build_reminder('monthly').periodicity_label).to eq('Pago mensual')
    end

    it 'retorna etiqueta generica para frecuencia desconocida' do
      expect(build_reminder('unknown').periodicity_label).to eq('Pago de nómina')
    end
  end

  describe '#next_period_label' do
    it 'CA1: retorna etiqueta de proximo pago semanal' do
      expect(build_reminder('weekly').next_period_label).to eq('Próximo pago semanal')
    end

    it 'CA2: retorna etiqueta de proxima quincena' do
      expect(build_reminder('biweekly').next_period_label).to eq('Próxima quincena')
    end

    it 'CA3: retorna etiqueta de proximo pago mensual' do
      expect(build_reminder('monthly').next_period_label).to eq('Próximo pago mensual')
    end

    it 'retorna etiqueta generica para frecuencia desconocida' do
      expect(build_reminder('unknown').next_period_label).to eq('Próxima nómina')
    end
  end

  describe '#payment_frequency' do
    it 'expone la frecuencia de pago' do
      reminder = build_reminder('biweekly')
      expect(reminder.payment_frequency).to eq('biweekly')
    end
  end
end
