# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmploymentInformationPresenter do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:employment_information) do
    create(:employment_information,
           user:,
           job_title: 'Desarrollador Senior',
           start_date: Date.new(2020, 1, 15),
           gross_salary_amount: 30_000.0,
           calculation_periodicity: 'monthly_calculation',
           payment_frequency: 'monthly_payment')
  end
  let(:presenter) { described_class.new(employment_information) }

  describe '#job_title' do
    it 'retorna el puesto de trabajo' do
      expect(presenter.job_title).to eq('Desarrollador Senior')
    end
  end

  describe '#formatted_start_date' do
    it 'formatea la fecha de ingreso correctamente' do
      expect(presenter.formatted_start_date).to eq('15/01/2020')
    end
  end

  describe '#calculation_periodicity_label' do
    it 'retorna la etiqueta en español para mensual' do
      expect(presenter.calculation_periodicity_label).to eq('Mensual')
    end

    it 'retorna la etiqueta correcta para cada periodicidad de cálculo' do
      {
        'weekly_calculation'   => 'Semanal',
        'biweekly_calculation' => 'Quincenal',
        'monthly_calculation'  => 'Mensual',
        'annual_calculation'   => 'Anual'
      }.each do |calc, label|
        info = create(:employment_information, user: create(:user),
                                               calculation_periodicity: calc,
                                               payment_frequency: 'monthly_payment')
        expect(described_class.new(info).calculation_periodicity_label).to eq(label)
      end
    end
  end

  describe '#payment_frequency_label' do
    it 'retorna la etiqueta en español para mensual' do
      expect(presenter.payment_frequency_label).to eq('Mensual')
    end

    it 'retorna la etiqueta correcta para cada frecuencia de pago' do
      {
        'weekly_payment'   => 'Semanal',
        'biweekly_payment' => 'Quincenal',
        'monthly_payment'  => 'Mensual'
      }.each do |pay, label|
        calc = pay == 'weekly_payment' ? 'weekly_calculation' : 'monthly_calculation'
        info = create(:employment_information, user: create(:user),
                                               calculation_periodicity: calc,
                                               payment_frequency: pay)
        expect(described_class.new(info).payment_frequency_label).to eq(label)
      end
    end
  end

  describe '#periodicity_label' do
    it 'delega a calculation_periodicity_label' do
      expect(presenter.periodicity_label).to eq(presenter.calculation_periodicity_label)
    end
  end

  describe '#original_salary_formatted' do
    it 'formatea el salario original con símbolo de moneda' do
      expect(presenter.original_salary_formatted).to include('$')
      expect(presenter.original_salary_formatted).to include('30')
    end
  end

  describe '#seniority_years, #seniority_months, #days_in_current_year' do
    it 'retorna valores enteros positivos o cero' do
      travel_to Date.new(2026, 6, 22) do
        presenter_on_date = described_class.new(employment_information)
        expect(presenter_on_date.seniority_years).to be_a(Integer)
        expect(presenter_on_date.seniority_months).to be_between(0, 11)
        expect(presenter_on_date.days_in_current_year).to be_positive
      end
    end
  end

  describe '#seniority_text' do
    it 'retorna una cadena descriptiva de la antigüedad' do
      travel_to Date.new(2026, 6, 22) do
        presenter_on_date = described_class.new(employment_information)
        expect(presenter_on_date.seniority_text).to be_a(String)
        expect(presenter_on_date.seniority_text).not_to be_empty
      end
    end
  end

  describe '#formatted_salary' do
    it 'retorna el salario diario formateado' do
      expect(presenter.formatted_salary(:daily)).to include('$')
    end

    it 'retorna el salario mensual formateado con el monto correcto' do
      expect(presenter.formatted_salary(:monthly)).to include('30')
    end
  end

  describe '#normalized_salaries' do
    it 'retorna un hash con todas las periodicidades' do
      salaries = presenter.normalized_salaries
      expect(salaries.keys).to contain_exactly(:daily, :weekly, :biweekly, :monthly, :yearly)
    end

    it 'todos los valores están formateados con símbolo de moneda' do
      presenter.normalized_salaries.each_value do |value|
        expect(value).to include('$')
      end
    end
  end
end
