# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PayrollProfile, type: :model do
  subject(:profile) { build(:payroll_profile) }

  describe 'validaciones' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:monthly_gross_salary) }
    it { is_expected.to validate_presence_of(:hire_date) }
    it { is_expected.to validate_presence_of(:savings_fund_percentage) }

    it {
      is_expected.to validate_numericality_of(:monthly_gross_salary)
        .is_greater_than(0)
    }

    it {
      is_expected.to validate_numericality_of(:savings_fund_percentage)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
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
  end
end
