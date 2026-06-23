# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmploymentInformation, type: :model do
  let(:user) { create(:user) }
  let(:employment_information) { build(:employment_information, user:) }

  describe 'asociaciones' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validaciones de presencia' do
    it { is_expected.to validate_presence_of(:job_title) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:gross_salary_amount) }
    it { is_expected.to validate_presence_of(:salary_periodicity) }
  end

  describe 'validación de numericidad de salario' do
    it { is_expected.to validate_numericality_of(:gross_salary_amount).is_greater_than(0) }

    context 'CA7: salario negativo' do
      it 'es inválido con salario negativo' do
        employment_information.gross_salary_amount = -100
        expect(employment_information).not_to be_valid
        expect(employment_information.errors[:gross_salary_amount]).to be_present
      end
    end

    context 'CA7: salario cero' do
      it 'es inválido con salario cero' do
        employment_information.gross_salary_amount = 0
        expect(employment_information).not_to be_valid
        expect(employment_information.errors[:gross_salary_amount]).to be_present
      end
    end
  end

  describe 'validación de start_date' do
    context 'CA6: fecha futura' do
      it 'es inválido con fecha de ingreso futura' do
        employment_information.start_date = Date.current + 1.day
        expect(employment_information).not_to be_valid
        expect(employment_information.errors[:start_date]).to be_present
      end
    end

    context 'fecha actual' do
      it 'es válido con fecha de ingreso igual a hoy' do
        employment_information.start_date = Date.current
        expect(employment_information).to be_valid
      end
    end

    context 'fecha pasada' do
      it 'es válido con fecha de ingreso pasada' do
        employment_information.start_date = Date.current - 1.year
        expect(employment_information).to be_valid
      end
    end
  end

  describe 'enum salary_periodicity' do
    it 'acepta periodicidades válidas' do
      %w[daily weekly biweekly monthly yearly].each do |periodicity|
        employment_information.salary_periodicity = periodicity
        expect(employment_information).to be_valid
      end
    end
  end

  describe 'unicidad de usuario' do
    it 'no permite dos registros para el mismo usuario' do
      create(:employment_information, user:)
      duplicate = build(:employment_information, user:)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe 'CA1: registro válido' do
    it 'es válido con todos los atributos correctos' do
      expect(employment_information).to be_valid
    end

    it 'se guarda correctamente en la base de datos' do
      expect { employment_information.save! }.to change(EmploymentInformation, :count).by(1)
    end
  end

  describe 'sincronización de PayrollProfile' do
    context 'cuando no existe PayrollProfile para el usuario' do
      it 'crea un PayrollProfile al guardar' do
        expect { employment_information.save! }.to change(PayrollProfile, :count).by(1)
      end

      it 'el PayrollProfile tiene el salario mensual normalizado' do
        employment_information.save!
        profile = user.reload.payroll_profile
        expected = EmploymentInformationServices::Calculator.normalize_salary(
          employment_information.gross_salary_amount,
          employment_information.salary_periodicity
        )[:monthly]
        expect(profile.monthly_gross_salary).to be_within(0.01).of(expected)
      end

      it 'el PayrollProfile tiene la fecha de ingreso correcta' do
        employment_information.save!
        expect(user.reload.payroll_profile.hire_date).to eq(employment_information.start_date)
      end
    end

    context 'cuando ya existe un PayrollProfile para el usuario' do
      before { employment_information.save! }

      it 'actualiza el PayrollProfile al modificar el salario' do
        employment_information.update!(gross_salary_amount: 50_000.0, salary_periodicity: 'monthly')
        expect(user.reload.payroll_profile.monthly_gross_salary).to be_within(0.01).of(50_000.0)
      end

      it 'no crea un PayrollProfile duplicado' do
        expect do
          employment_information.update!(gross_salary_amount: 60_000.0)
        end.not_to change(PayrollProfile, :count)
      end
    end
  end
end
