# frozen_string_literal: true

module Payroll
  # Calcula salario neto mensual aplicando ISR (tabla 2026) e IMSS obrero.
  class NetSalaryCalculator
    ISR_TABLE_KEY = :isr_table

    def initialize(monthly_gross_salary:)
      @monthly_gross_salary = BigDecimal(monthly_gross_salary.to_s)
    end

    def call
      isr = calculate_isr
      imss = calculate_imss
      net = (monthly_gross_salary - isr - imss).round(2)
      Result.success(data: build_data(isr, imss, net))
    rescue StandardError => e
      Result.failure(error: e.message)
    end

    private

    attr_reader :monthly_gross_salary

    def build_data(isr, imss, net)
      {
        gross: monthly_gross_salary.round(2),
        isr_withholding: isr,
        imss_withholding: imss,
        net: net
      }
    end

    def calculate_isr
      bracket = find_isr_bracket
      return BigDecimal('0') unless bracket

      lower_limit = BigDecimal(bracket[:lower_limit].to_s)
      fixed_quota = BigDecimal(bracket[:fixed_quota].to_s)
      rate = BigDecimal(bracket[:rate].to_s)
      ((monthly_gross_salary - lower_limit) * rate + fixed_quota).round(2)
    end

    def find_isr_bracket
      PayrollConstants[ISR_TABLE_KEY].find do |bracket|
        lower = BigDecimal(bracket[:lower_limit].to_s)
        upper = BigDecimal(bracket[:upper_limit].to_s)
        monthly_gross_salary >= lower && monthly_gross_salary <= upper
      end
    end

    def calculate_imss
      rate = BigDecimal(PayrollConstants[:imss_worker_rate].to_s)
      (monthly_gross_salary * rate).round(2)
    end
  end
end
