# frozen_string_literal: true

module Api
  module V1
    # Endpoints JSON para calcular aguinaldo, fondo de ahorro y salario neto.
    class PayrollCalculationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_payroll_profile

      def aguinaldo
        result = Payroll::AguinaldoCalculator.new(
          monthly_gross_salary: @payroll_profile.monthly_gross_salary,
          hire_date: @payroll_profile.hire_date
        ).call

        render_result(result)
      end

      def savings_fund
        result = Payroll::SavingsFundCalculator.new(
          monthly_gross_salary: @payroll_profile.monthly_gross_salary,
          savings_fund_percentage: @payroll_profile.savings_fund_percentage
        ).call

        render_result(result)
      end

      def net_salary
        result = Payroll::NetSalaryCalculator.new(
          monthly_gross_salary: @payroll_profile.monthly_gross_salary
        ).call

        render_result(result)
      end

      private

      def set_payroll_profile
        @payroll_profile = current_user.payroll_profile
        return if @payroll_profile.present?

        render json: {
          error: {
            code: 'not_found',
            message: 'Perfil de nómina no encontrado. Registra tu información laboral primero.'
          }
        }, status: :not_found
      end

      def render_result(result)
        if result.success?
          render json: { record: PayrollCalculationSerializer.new(result.data).as_json }
        else
          render json: { error: { code: result.error, message: result.message } },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
