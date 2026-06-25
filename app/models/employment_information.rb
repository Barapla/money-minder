# frozen_string_literal: true

# Registra la información laboral del usuario: puesto, fecha de ingreso y salario.
class EmploymentInformation < ApplicationRecord
  belongs_to :user

  enum :calculation_periodicity, {
    daily_calculation: 'daily',
    weekly_calculation: 'weekly',
    biweekly_calculation: 'biweekly',
    monthly_calculation: 'monthly',
    annual_calculation: 'annual'
  }

  enum :payment_frequency, {
    weekly_payment: 'weekly',
    biweekly_payment: 'biweekly',
    monthly_payment: 'monthly'
  }

  validates :job_title, presence: true
  validates :start_date, presence: true
  validates :gross_salary_amount, presence: true, numericality: { greater_than: 0 }
  validates :calculation_periodicity, presence: true
  validates :payment_frequency, presence: true
  validates :user_id, uniqueness: true
  validate :start_date_not_in_future

  after_save :sync_payroll_profile

  private

  def sync_payroll_profile
    db_val = self.class.calculation_periodicities[calculation_periodicity.to_s]
    monthly_salary = EmploymentInformationServices::Calculator.normalize_salary(
      gross_salary_amount, db_val
    )[:monthly]
    return if monthly_salary.nil? || monthly_salary <= 0

    payroll_attrs = { monthly_gross_salary: monthly_salary, base_salary: monthly_salary, hire_date: start_date }
    upsert_payroll_profile(payroll_attrs)
  end

  def upsert_payroll_profile(attrs)
    if (profile = user.payroll_profile)
      profile.update!(attrs)
    else
      user.create_payroll_profile!(attrs)
    end
  end

  def start_date_not_in_future
    return unless start_date.present? && start_date > Date.current

    errors.add(:start_date, :not_in_future, message: 'debe ser presente o pasada')
  end
end
