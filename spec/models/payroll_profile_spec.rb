# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PayrollProfile, type: :model do
  subject(:profile) { build(:payroll_profile) }

  describe 'validaciones' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:monthly_gross_salary) }
    it { is_expected.to validate_presence_of(:base_salary) }
    it { is_expected.to validate_presence_of(:hire_date) }
    it { is_expected.to validate_presence_of(:savings_fund_percentage) }
    it { is_expected.to validate_presence_of(:savings_fund_rate) }

    it {
      is_expected.to validate_numericality_of(:monthly_gross_salary)
        .is_greater_than(0)
    }

    it {
      is_expected.to validate_numericality_of(:base_salary)
        .is_greater_than(0)
    }

    it {
      is_expected.to validate_numericality_of(:savings_fund_percentage)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    }

    it {
      is_expected.to validate_numericality_of(:savings_fund_rate)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    }

    it {
      is_expected.to validate_numericality_of(:custom_isr_rate)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
        .allow_nil
    }

    it {
      is_expected.to validate_numericality_of(:custom_imss_rate)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
        .allow_nil
    }

    it { is_expected.to validate_uniqueness_of(:user_id) }

    context 'cuando hire_date está en el futuro' do
      it 'agrega error en hire_date' do
        profile.hire_date = Date.current + 1.day
        expect(profile).not_to be_valid
        expect(profile.errors[:hire_date]).to be_present
      end
    end

    context 'cuando hire_date es hoy' do
      it 'es válido' do
        profile.hire_date = Date.current
        expect(profile).to be_valid
      end
    end

    context 'custom_isr_rate fuera de rango' do
      it 'es inválido cuando supera 100' do
        profile.custom_isr_rate = 101
        expect(profile).not_to be_valid
        expect(profile.errors[:custom_isr_rate]).to be_present
      end

      it 'es inválido cuando es negativo' do
        profile.custom_isr_rate = -1
        expect(profile).not_to be_valid
      end

      it 'es válido cuando es nil' do
        profile.custom_isr_rate = nil
        expect(profile).to be_valid
      end
    end

    context 'custom_imss_rate fuera de rango' do
      it 'es inválido cuando supera 100' do
        profile.custom_imss_rate = 101
        expect(profile).not_to be_valid
        expect(profile.errors[:custom_imss_rate]).to be_present
      end

      it 'es válido cuando es nil' do
        profile.custom_imss_rate = nil
        expect(profile).to be_valid
      end
    end

    context 'non_taxable_bonuses con estructura válida' do
      it 'es válido con hash de conceptos positivos' do
        profile.non_taxable_bonuses = { 'transporte' => 2000, 'vales' => 500 }
        expect(profile).to be_valid
      end

      it 'es válido con hash vacío' do
        profile.non_taxable_bonuses = {}
        expect(profile).to be_valid
      end

      it 'es inválido con valores negativos' do
        profile.non_taxable_bonuses = { 'transporte' => -100 }
        expect(profile).not_to be_valid
        expect(profile.errors[:non_taxable_bonuses]).to be_present
      end

      it 'es inválido con valores no numéricos' do
        profile.non_taxable_bonuses = { 'transporte' => 'gratis' }
        expect(profile).not_to be_valid
        expect(profile.errors[:non_taxable_bonuses]).to be_present
      end
    end
  end

  describe '#monthly_salary (deprecado)' do
    it 'retorna base_salary con advertencia de deprecación en el log' do
      expect(Rails.logger).to receive(:warn).with(match(/deprecado/))
      expect(profile.monthly_salary).to eq(profile.base_salary)
    end
  end
end
