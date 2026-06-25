# frozen_string_literal: true

# Migra salary_periodicity a calculation_periodicity y payment_frequency independientes.
class SeparateCalculationAndPaymentPeriodicity < ActiveRecord::Migration[7.2]
  SALARY_TO_CALCULATION = {
    'daily' => 'daily',
    'weekly' => 'weekly',
    'biweekly' => 'biweekly',
    'monthly' => 'monthly',
    'yearly' => 'annual'
  }.freeze

  SALARY_TO_PAYMENT = {
    'daily' => 'weekly',
    'weekly' => 'weekly',
    'biweekly' => 'biweekly',
    'monthly' => 'monthly',
    'yearly' => 'monthly'
  }.freeze

  def up # rubocop:disable Metrics/MethodLength
    add_column :employment_informations, :calculation_periodicity, :string
    add_column :employment_informations, :payment_frequency, :string

    EmploymentInformation.reset_column_information
    EmploymentInformation.find_each do |ei|
      sp = ei.read_attribute(:salary_periodicity).to_s
      ei.update_columns(
        calculation_periodicity: SALARY_TO_CALCULATION.fetch(sp, 'monthly'),
        payment_frequency: SALARY_TO_PAYMENT.fetch(sp, 'monthly')
      )
    end

    change_column_null :employment_informations, :calculation_periodicity, false
    change_column_null :employment_informations, :payment_frequency, false

    remove_column :employment_informations, :salary_periodicity
  end

  def down
    add_column :employment_informations, :salary_periodicity, :string

    EmploymentInformation.reset_column_information
    EmploymentInformation.find_each do |ei|
      cp = ei.read_attribute(:calculation_periodicity).to_s
      salary_periodicity = { 'annual' => 'yearly' }.fetch(cp, cp)
      ei.update_columns(salary_periodicity: salary_periodicity)
    end

    change_column_null :employment_informations, :salary_periodicity, false

    remove_column :employment_informations, :calculation_periodicity
    remove_column :employment_informations, :payment_frequency
  end
end
