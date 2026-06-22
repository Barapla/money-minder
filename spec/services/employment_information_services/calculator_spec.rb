# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmploymentInformationServices::Calculator do
  include ActiveSupport::Testing::TimeHelpers
  describe '.calculate_seniority' do
    context 'CA2: calcula antigüedad correctamente' do
      it 'retorna años, meses y días en el año actual' do
        travel_to Date.new(2026, 6, 22) do
          start_date = Date.new(2023, 3, 10)
          result = described_class.calculate_seniority(start_date)

          expect(result[:years]).to eq(3)
          expect(result[:months]).to eq(3)
          expect(result[:days_in_current_year]).to be_a(Integer)
          expect(result[:days_in_current_year]).to be_positive
        end
      end

      it 'calcula 0 años para menos de 1 año de antigüedad' do
        travel_to Date.new(2026, 6, 22) do
          start_date = Date.new(2026, 1, 15)
          result = described_class.calculate_seniority(start_date)

          expect(result[:years]).to eq(0)
          expect(result[:months]).to be_between(0, 12)
        end
      end

      it 'calcula días en el año actual desde el inicio del año cuando inició antes' do
        travel_to Date.new(2026, 6, 22) do
          start_date = Date.new(2020, 5, 10)
          result = described_class.calculate_seniority(start_date)

          expected_days = (Date.new(2026, 6, 22) - Date.new(2026, 1, 1)).to_i + 1
          expect(result[:days_in_current_year]).to eq(expected_days)
        end
      end

      it 'calcula días en el año actual desde start_date cuando inició este año' do
        travel_to Date.new(2026, 6, 22) do
          start_date = Date.new(2026, 3, 15)
          result = described_class.calculate_seniority(start_date)

          expected_days = (Date.new(2026, 6, 22) - Date.new(2026, 3, 15)).to_i + 1
          expect(result[:days_in_current_year]).to eq(expected_days)
        end
      end

      it 'retorna 0 años y 0 meses para inicio en el día actual' do
        travel_to Date.new(2026, 6, 22) do
          start_date = Date.new(2026, 6, 22)
          result = described_class.calculate_seniority(start_date)

          expect(result[:years]).to eq(0)
          expect(result[:months]).to eq(0)
        end
      end
    end
  end

  describe '.normalize_salary' do
    context 'CA3: normalización desde salario mensual' do
      let(:monthly_amount) { 30_000.0 }
      let(:result) { described_class.normalize_salary(monthly_amount, 'monthly') }

      it 'calcula la tasa diaria correctamente (30000 / 30 = 1000)' do
        expect(result[:daily]).to eq(1000.0)
      end

      it 'calcula el salario semanal (diario × 7)' do
        expect(result[:weekly]).to eq(7000.0)
      end

      it 'calcula el salario quincenal (diario × 15)' do
        expect(result[:biweekly]).to eq(15_000.0)
      end

      it 'retorna el mismo monto mensual (diario × 30)' do
        expect(result[:monthly]).to eq(30_000.0)
      end

      it 'calcula el salario anual (diario × 365)' do
        expect(result[:yearly]).to eq(365_000.0)
      end
    end

    context 'normalización desde salario diario' do
      let(:daily_amount) { 500.0 }
      let(:result) { described_class.normalize_salary(daily_amount, 'daily') }

      it 'mantiene el monto diario igual' do
        expect(result[:daily]).to eq(500.0)
      end

      it 'calcula semanal como diario × 7' do
        expect(result[:weekly]).to eq(3500.0)
      end

      it 'calcula mensual como diario × 30' do
        expect(result[:monthly]).to eq(15_000.0)
      end

      it 'calcula anual como diario × 365' do
        expect(result[:yearly]).to eq(182_500.0)
      end
    end

    context 'normalización desde salario semanal' do
      let(:weekly_amount) { 3500.0 }
      let(:result) { described_class.normalize_salary(weekly_amount, 'weekly') }

      it 'calcula la tasa diaria (3500 / 7 = 500)' do
        expect(result[:daily]).to eq(500.0)
      end

      it 'mantiene el monto semanal igual' do
        expect(result[:weekly]).to eq(3500.0)
      end
    end

    context 'normalización desde salario quincenal' do
      let(:biweekly_amount) { 7500.0 }
      let(:result) { described_class.normalize_salary(biweekly_amount, 'biweekly') }

      it 'calcula la tasa diaria (7500 / 15 = 500)' do
        expect(result[:daily]).to eq(500.0)
      end
    end

    context 'normalización desde salario anual' do
      let(:yearly_amount) { 182_500.0 }
      let(:result) { described_class.normalize_salary(yearly_amount, 'yearly') }

      it 'calcula la tasa diaria (182500 / 365 = 500)' do
        expect(result[:daily]).to eq(500.0)
      end

      it 'calcula mensual correctamente' do
        expect(result[:monthly]).to eq(15_000.0)
      end
    end

    context 'acepta símbolos como periodicidad' do
      it 'normaliza cuando la periodicidad es un símbolo' do
        result = described_class.normalize_salary(30_000.0, :monthly)
        expect(result[:daily]).to eq(1000.0)
      end
    end
  end
end
