# frozen_string_literal: true

# Almacena la configuración de nómina del usuario para calcular beneficios fiscales.
class PayrollProfile < ApplicationRecord
  belongs_to :user

  validates :monthly_gross_salary, presence: true, numericality: { greater_than: 0 }
  validates :hire_date, presence: true
  validates :savings_fund_percentage, presence: true,
                                      numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :user_id, uniqueness: true
  validate :hire_date_not_in_future

  private

  def hire_date_not_in_future
    return unless hire_date.present? && hire_date > Date.current

    errors.add(:hire_date, :not_in_future, message: 'debe ser presente o pasada')
  end
end
