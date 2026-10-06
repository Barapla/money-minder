# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PayrollServices::ReminderGenerator, type: :service do
  let(:user) { create(:user) }
  let(:start_date) { Date.new(2024, 1, 1) }

  # employment_information auto-crea payroll_profile via after_save :sync_payroll_profile
  let(:employment_info) do
    create(:employment_information, user:, start_date:,
                                    calculation_periodicity: 'biweekly_calculation',
                                    payment_frequency: 'biweekly_payment',
                                    gross_salary_amount: 30_000)
  end

  subject(:generator) { described_class.new(user) }

  before { employment_info }

  describe '#generate' do
    context 'CA3: usuario sin EmploymentInformation' do
      before { employment_info.destroy }

      it 'retorna arreglo vacío' do
        result = described_class.new(user.reload).generate(from_date: Date.today, to_date: Date.today + 30)
        expect(result).to eq([])
      end
    end

    context 'CA3: usuario sin PayrollProfile' do
      before { user.payroll_profile.destroy }

      it 'retorna arreglo vacío' do
        result = described_class.new(user.reload).generate(from_date: Date.today, to_date: Date.today + 30)
        expect(result).to eq([])
      end
    end

    context 'CA1: usuario con payment_frequency biweekly' do
      let(:from_date) { Date.new(2024, 3, 1) }
      let(:to_date) { Date.new(2024, 3, 31) }

      it 'retorna instancias de PayrollReminder' do
        reminders = generator.generate(from_date:, to_date:)
        expect(reminders).to all(be_a(PayrollReminder))
      end

      it 'genera recordatorios en días hábiles (lunes a viernes)' do
        reminders = generator.generate(from_date:, to_date:)
        expect(reminders).not_to be_empty
        reminders.each do |reminder|
          expect(reminder.date.wday).to be_between(1, 5),
                                        "Se esperaba día hábil, se obtuvo #{reminder.date}"
        end
      end

      it 'todos los recordatorios están dentro del rango' do
        reminders = generator.generate(from_date:, to_date:)
        reminders.each do |reminder|
          expect(reminder.date).to be >= from_date
          expect(reminder.date).to be <= to_date
        end
      end

      it 'incluye el monto neto calculado positivo' do
        reminders = generator.generate(from_date:, to_date:)
        reminders.each do |reminder|
          expect(reminder.net_amount).to be > 0
        end
      end

      it 'incluye el breakdown del cálculo con las claves esperadas' do
        reminders = generator.generate(from_date:, to_date:)
        reminders.each do |reminder|
          expect(reminder.calculation_breakdown).to include(:base_salary, :net_salary, :isr_estimated)
        end
      end

      it 'asigna la frecuencia de pago correcta' do
        reminders = generator.generate(from_date:, to_date:)
        reminders.each do |reminder|
          expect(reminder.payment_frequency).to eq('biweekly')
        end
      end
    end

    context 'CA2: usuario con payment_frequency monthly' do
      before do
        employment_info.update!(
          calculation_periodicity: 'monthly_calculation',
          payment_frequency: 'monthly_payment',
          start_date: Date.new(2024, 1, 15)
        )
      end

      it 'genera exactamente un recordatorio por mes en el rango' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expect(reminders.length).to eq(1)
      end

      it 'la fecha del recordatorio coincide con el día de inicio' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expect(reminders.first.date.day).to eq(15)
      end

      it 'genera múltiples recordatorios para rangos de varios meses' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 5, 31))
        expect(reminders.length).to eq(3)
      end
    end

    context 'CA6: usuario con payment_frequency weekly' do
      before do
        employment_info.update!(
          calculation_periodicity: 'weekly_calculation',
          payment_frequency: 'weekly_payment',
          start_date: Date.new(2024, 1, 1)
        )
      end

      it 'genera recordatorios siempre en jueves' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expect(reminders).not_to be_empty
        reminders.each do |reminder|
          expect(reminder.date.wday).to eq(4),
                                        "Se esperaba jueves, se obtuvo #{reminder.date}"
        end
      end

      it 'genera recordatorios cada 7 días' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expect(reminders).not_to be_empty
        reminders.each_cons(2) do |a, b|
          expect((b.date - a.date).to_i).to eq(7)
        end
      end
    end

    context 'CA4: monto neto se recalcula con datos actuales del PayrollProfile' do
      it 'refleja los cambios en el PayrollProfile al regenerar' do
        reminders_before = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        net_before = reminders_before.first.net_amount

        user.payroll_profile.update!(base_salary: 100_000, monthly_gross_salary: 100_000)

        reminders_after = described_class.new(user.reload).generate(
          from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31)
        )
        expect(reminders_after.first.net_amount).to be > net_before
      end
    end

    context 'CA1: monto neto escalado por payment_frequency — weekly' do
      before do
        employment_info.update!(calculation_periodicity: 'weekly_calculation', payment_frequency: 'weekly_payment')
        user.payroll_profile.update!(base_salary: 30_000, monthly_gross_salary: 30_000,
                                     savings_fund_rate: 0, custom_isr_rate: 0, custom_imss_rate: 0)
      end

      it 'net_amount es la fraccion semanal del salario mensual neto (7/30)' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expected = (BigDecimal('30000') * 7 / 30).round(2)
        expect(reminders.first.net_amount).to eq(expected)
      end

      it 'net_amount es menor que el salario mensual completo' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        monthly_net = user.payroll_profile.base_salary.to_d
        expect(reminders.first.net_amount).to be < monthly_net
      end
    end

    context 'CA2: monto neto escalado por payment_frequency — biweekly' do
      it 'net_amount es la mitad del salario mensual neto (15/30)' do
        user.payroll_profile.update!(base_salary: 30_000, monthly_gross_salary: 30_000,
                                     savings_fund_rate: 0, custom_isr_rate: 0, custom_imss_rate: 0)
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expected = (BigDecimal('30000') * 15 / 30).round(2)
        expect(reminders.first.net_amount).to eq(expected)
      end
    end

    context 'CA3: monto neto escalado por payment_frequency — monthly' do
      before do
        employment_info.update!(
          calculation_periodicity: 'monthly_calculation',
          payment_frequency: 'monthly_payment',
          start_date: Date.new(2024, 1, 15)
        )
        user.payroll_profile.update!(base_salary: 30_000, monthly_gross_salary: 30_000,
                                     savings_fund_rate: 0, custom_isr_rate: 0, custom_imss_rate: 0)
      end

      it 'net_amount es el salario mensual completo' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expected = BigDecimal('30000')
        expect(reminders.first.net_amount).to eq(expected)
      end
    end

    context 'CA2: calculo mensual con pago quincenal genera dos recordatorios por mes' do
      before do
        employment_info.update!(
          calculation_periodicity: 'monthly_calculation',
          payment_frequency: 'biweekly_payment',
          start_date: Date.new(2024, 1, 1)
        )
        user.payroll_profile.update!(base_salary: 10_000, monthly_gross_salary: 10_000,
                                     savings_fund_rate: 0, custom_isr_rate: 0, custom_imss_rate: 0)
      end

      it 'genera dos recordatorios por mes' do
        reminders = generator.generate(from_date: Date.new(2025, 7, 1), to_date: Date.new(2025, 7, 31))
        expect(reminders.length).to eq(2)
      end

      it 'cada recordatorio es el 50% del salario mensual neto' do
        reminders = generator.generate(from_date: Date.new(2025, 7, 1), to_date: Date.new(2025, 7, 31))
        expected = (BigDecimal('10000') * 15 / 30).round(2)
        reminders.each do |reminder|
          expect(reminder.net_amount).to eq(expected)
        end
      end
    end

    context 'CA3: calculo anual con pago mensual genera un recordatorio por mes' do
      before do
        employment_info.update!(
          calculation_periodicity: 'annual_calculation',
          payment_frequency: 'monthly_payment',
          start_date: Date.new(2024, 1, 15)
        )
        user.payroll_profile.update!(base_salary: 5_000, monthly_gross_salary: 5_000,
                                     savings_fund_rate: 0, custom_isr_rate: 0, custom_imss_rate: 0)
      end

      it 'genera un recordatorio mensual' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 5, 31))
        expect(reminders.length).to eq(3)
      end

      it 'el monto del recordatorio es el salario mensual completo' do
        reminders = generator.generate(from_date: Date.new(2024, 3, 1), to_date: Date.new(2024, 3, 31))
        expected = BigDecimal('5000')
        expect(reminders.first.net_amount).to eq(expected)
      end
    end

    context 'biweekly: fechas fijas en el 15 y el 30 de cada mes' do
      it 'genera exactamente dos recordatorios por mes' do
        reminders = generator.generate(from_date: Date.new(2025, 7, 1), to_date: Date.new(2025, 7, 31))
        expect(reminders.length).to eq(2)
      end

      it 'el primer recordatorio cae el 15 (o día hábil anterior si es fin de semana)' do
        reminders = generator.generate(from_date: Date.new(2025, 7, 1), to_date: Date.new(2025, 7, 31))
        first_date = reminders.min_by(&:date).date
        expect(first_date).to be <= Date.new(2025, 7, 15)
        expect(first_date.wday).to be_between(1, 5)
      end

      it 'el segundo recordatorio cae el 30 (o día hábil anterior si es fin de semana)' do
        reminders = generator.generate(from_date: Date.new(2025, 7, 1), to_date: Date.new(2025, 7, 31))
        second_date = reminders.max_by(&:date).date
        expect(second_date).to be <= Date.new(2025, 7, 30)
        expect(second_date.wday).to be_between(1, 5)
      end

      it 'ajusta el 15 de marzo 2025 (sábado) al viernes anterior' do
        reminders = generator.generate(from_date: Date.new(2025, 3, 1), to_date: Date.new(2025, 3, 15))
        first_date = reminders.first.date
        expect(first_date).to eq(Date.new(2025, 3, 14))
      end

      it 'nunca ajusta hacia adelante del 15 o del 30' do
        reminders = generator.generate(from_date: Date.new(2025, 1, 1), to_date: Date.new(2025, 12, 31))
        reminders.each do |reminder|
          date = reminder.date
          if date.day <= 15
            expect(date.day).to be <= 15, "Primera quincena #{date} supera el día 15"
          else
            max_day = [30, Date.new(date.year, date.month, -1).day].min
            expect(date.day).to be <= max_day, "Segunda quincena #{date} supera el día #{max_day}"
          end
        end
      end
    end
  end
end
