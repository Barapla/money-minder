# frozen_string_literal: true

module PayrollServices
  # Calcula salario neto separando sueldo base gravado y bonos no gravados con tasas configurables.
  class Calculator
    def initialize(payroll_profile)
      @profile = payroll_profile
    end

    def call
      Result.success(data: build_data)
    rescue StandardError => e
      Result.failure(error: :calculation_error, message: e.message)
    end

    def calculate_taxable_base
      BigDecimal(@profile.base_salary.to_s)
    end

    def calculate_total_bonuses
      BigDecimal(@profile.non_taxable_bonuses.values.sum.to_s)
    end

    def calculate_savings_fund_employee_contribution
      (calculate_taxable_base * savings_fund_rate / BigDecimal('100')).round(2)
    end

    def calculate_savings_fund_employer_contribution
      calculate_savings_fund_employee_contribution
    end

    def calculate_isr_estimated
      (calculate_taxable_base * isr_rate / BigDecimal('100')).round(2)
    end

    def calculate_imss_estimated
      (calculate_taxable_base * imss_rate / BigDecimal('100')).round(2)
    end

    def calculate_net_salary
      (calculate_taxable_base +
        calculate_total_bonuses -
        calculate_savings_fund_employee_contribution -
        calculate_isr_estimated -
        calculate_imss_estimated).round(2)
    end

    private

    attr_reader :profile

    def savings_fund_rate
      BigDecimal((@profile.savings_fund_rate || PayrollConstants::DEFAULT_SAVINGS_FUND_RATE).to_s)
    end

    def isr_rate
      BigDecimal((@profile.custom_isr_rate || PayrollConstants::DEFAULT_ISR_RATE).to_s)
    end

    def imss_rate
      BigDecimal((@profile.custom_imss_rate || PayrollConstants::DEFAULT_IMSS_RATE).to_s)
    end

    def build_data
      {
        base_salary: calculate_taxable_base,
        total_bonuses: calculate_total_bonuses,
        savings_fund_employee: calculate_savings_fund_employee_contribution,
        savings_fund_employer: calculate_savings_fund_employer_contribution,
        isr_estimated: calculate_isr_estimated,
        imss_estimated: calculate_imss_estimated,
        net_salary: calculate_net_salary
      }
    end
  end
end
