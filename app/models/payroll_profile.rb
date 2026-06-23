# frozen_string_literal: true

# Almacena la configuración de nómina del usuario para calcular beneficios fiscales.
class PayrollProfile < ApplicationRecord
  belongs_to :user

  validates :base_salary, presence: true, numericality: { greater_than: 0 }
  validates :monthly_gross_salary, presence: true, numericality: { greater_than: 0 }
  validates :hire_date, presence: true
  validates :savings_fund_percentage, presence: true,
                                      numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :savings_fund_rate, presence: true,
                                numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :custom_isr_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :custom_imss_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :user_id, uniqueness: true
  validate :hire_date_not_in_future
  validate :non_taxable_bonuses_structure

  def monthly_salary
    warn '[DEPRECATED] monthly_salary esta deprecado, usar base_salary'
    base_salary
  end

  private

  def hire_date_not_in_future
    return unless hire_date.present? && hire_date > Date.current

    errors.add(:hire_date, :not_in_future, message: 'debe ser presente o pasada')
  end

  def non_taxable_bonuses_structure
    return if non_taxable_bonuses.blank?

    return if non_taxable_bonuses.is_a?(Hash) &&
              non_taxable_bonuses.values.all? { |v| v.is_a?(Numeric) && v >= 0 }

    errors.add(:non_taxable_bonuses, 'debe ser un hash con valores numericos positivos')
  end
end
