# frozen_string_literal: true

module Payroll
  # Calcula el aguinaldo anual completo o proporcional según antigüedad.
  class AguinaldoCalculator
    def initialize(monthly_gross_salary:, hire_date:, calculation_date: Date.current)
      @monthly_gross_salary = BigDecimal(monthly_gross_salary.to_s)
      @hire_date = hire_date
      @calculation_date = calculation_date
    end

    def call
      days_worked = (calculation_date - hire_date).to_i
      return invalid_dates_failure if days_worked.negative?

      result = days_worked < 365 ? proportional_aguinaldo(days_worked) : full_years_aguinaldo(days_worked)
      Result.success(data: result)
    rescue StandardError => e
      Result.failure(error: e.message)
    end

    private

    attr_reader :monthly_gross_salary, :hire_date, :calculation_date

    def daily_salary
      monthly_gross_salary / BigDecimal('30')
    end

    def aguinaldo_days
      BigDecimal(PayrollConstants[:aguinaldo_days].to_s)
    end

    def proportional_aguinaldo(days_worked)
      amount = (daily_salary * aguinaldo_days * BigDecimal(days_worked.to_s) / BigDecimal('365')).round(2)
      { amount: amount, days_worked: days_worked, proportional: true }
    end

    def full_years_aguinaldo(days_worked)
      completed_years = days_worked / 365
      amount = (daily_salary * aguinaldo_days * BigDecimal(completed_years.to_s)).round(2)
      { amount: amount, days_worked: days_worked, proportional: false }
    end

    def invalid_dates_failure
      Result.failure(
        error: :invalid_dates,
        message: 'La fecha de calculo no puede ser anterior a la fecha de ingreso'
      )
    end
  end
end
