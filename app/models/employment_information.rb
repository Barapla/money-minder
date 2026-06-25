# frozen_string_literal: true

# Registra la información laboral del usuario: puesto, fecha de ingreso y salario.
class EmploymentInformation < ApplicationRecord
  belongs_to :user

  enum :calculation_periodicity, {
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

  COMPATIBLE_PAYMENT_FREQUENCIES = {
    'weekly_calculation' => %w[weekly_payment biweekly_payment monthly_payment],
    'biweekly_calculation' => %w[biweekly_payment monthly_payment],
    'monthly_calculation' => %w[biweekly_payment monthly_payment],
    'annual_calculation' => %w[monthly_payment]
  }.freeze

  validates :job_title, presence: true
  validates :start_date, presence: true
  validates :gross_salary_amount, presence: true, numericality: { greater_than: 0 }
  validates :calculation_periodicity, presence: true
  validates :payment_frequency, presence: true
  validates :user_id, uniqueness: true
  validate :start_date_not_in_future
  validate :payment_frequency_compatible_with_calculation

  after_save :sync_payroll_profile

  private

  def sync_payroll_profile
    calc_db_value = self.class.calculation_periodicities[calculation_periodicity.to_s]
    monthly_salary = EmploymentInformationServices::Calculator.normalize_salary(
      gross_salary_amount, calc_db_value.to_s
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

  def payment_frequency_compatible_with_calculation
    return if calculation_periodicity.blank? || payment_frequency.blank?

    allowed = COMPATIBLE_PAYMENT_FREQUENCIES.fetch(calculation_periodicity.to_s, [])
    return if allowed.include?(payment_frequency.to_s)

    errors.add(:payment_frequency, 'no es compatible con la periodicidad de cálculo seleccionada')
  end

  def start_date_not_in_future
    return unless start_date.present? && start_date > Date.current

    errors.add(:start_date, :not_in_future, message: 'debe ser presente o pasada')
  end
end
