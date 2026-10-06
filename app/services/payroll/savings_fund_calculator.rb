# frozen_string_literal: true

module Payroll
  # Calcula fondo de ahorro mensual con tope 1.3x UMA mensual 2026.
  class SavingsFundCalculator
    def initialize(monthly_gross_salary:, savings_fund_percentage:)
      @monthly_gross_salary = BigDecimal(monthly_gross_salary.to_s)
      @savings_fund_percentage = BigDecimal(savings_fund_percentage.to_s)
    end

    def call
      calculated = (monthly_gross_salary * savings_fund_percentage / BigDecimal('100')).round(2)
      cap = uma_monthly_cap
      capped = [calculated, cap].min.round(2)
      build_result(capped, calculated > cap)
    rescue ArgumentError, TypeError => e
      Result.failure(error: :configuracion_invalida, message: "#{e.class}: #{e.message}")
    end

    private

    attr_reader :monthly_gross_salary, :savings_fund_percentage

    def uma_monthly_cap
      uma_daily = PayrollConstants[:uma_daily]
      raise ArgumentError, 'PayrollConstants[:uma_daily] no está configurado' if uma_daily.nil?

      (BigDecimal(uma_daily.to_s) * BigDecimal('30.4') * BigDecimal('1.3')).round(2)
    end

    def build_result(capped, uma_cap_applied)
      Result.success(data: {
                       employee_contribution: capped,
                       employer_contribution: capped,
                       monthly_total: (capped * 2).round(2),
                       uma_cap_applied: uma_cap_applied
                     })
    end
  end
end
