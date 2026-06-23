# frozen_string_literal: true

# Registra la información laboral del usuario: puesto, fecha de ingreso y salario.
class EmploymentInformation < ApplicationRecord
  belongs_to :user

  enum :salary_periodicity, {
    daily: 'daily', weekly: 'weekly', biweekly: 'biweekly', monthly: 'monthly', yearly: 'yearly'
  }

  validates :job_title, presence: true
  validates :start_date, presence: true
  validates :gross_salary_amount, presence: true, numericality: { greater_than: 0 }
  validates :salary_periodicity, presence: true
  validates :user_id, uniqueness: true
  validate :start_date_not_in_future

  after_save :sync_payroll_profile

  private

  def sync_payroll_profile
    monthly_salary = EmploymentInformationServices::Calculator.normalize_salary(
      gross_salary_amount, salary_periodicity
    )[:monthly]

    payroll_attrs = { monthly_gross_salary: monthly_salary, base_salary: monthly_salary, hire_date: start_date }

    if (profile = user.payroll_profile)
      profile.update!(payroll_attrs)
    else
      user.create_payroll_profile!(payroll_attrs)
    end
  end

  def start_date_not_in_future
    return unless start_date.present? && start_date > Date.current

    errors.add(:start_date, :not_in_future, message: 'debe ser presente o pasada')
  end
end
