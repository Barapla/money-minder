# frozen_string_literal: true

# Gestiona el CRUD de información laboral del usuario.
class EmploymentInformationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employment_information, only: %i[show edit update]

  def show
    @presenter = EmploymentInformationPresenter.new(@employment_information)
    @payroll_profile = current_user.payroll_profile
    load_payroll_calculations
  end

  def new
    @employment_information = EmploymentInformation.new
  end

  def create
    @employment_information = current_user.build_employment_information(employment_information_params)
    if @employment_information.save
      redirect_to employment_information_path, notice: 'Información laboral guardada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @employment_information.update(employment_information_params)
      redirect_to employment_information_path, notice: 'Información laboral actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_employment_information
    @employment_information = EmploymentInformation.find_by(user_id: current_user.id)
    return unless @employment_information.nil?

    redirect_to new_employment_information_path, alert: 'No tienes información laboral registrada.'
  end

  def employment_information_params
    params.require(:employment_information).permit(
      :job_title, :start_date, :gross_salary_amount, :salary_periodicity
    )
  end

  def load_payroll_calculations
    return unless @payroll_profile

    @net_salary_result = PayrollServices::Calculator.new(@payroll_profile).call
    @aguinaldo_result = calculate_aguinaldo(@payroll_profile)
    @savings_fund_result = calculate_savings_fund(@payroll_profile)
  end

  def calculate_aguinaldo(payroll_profile)
    Payroll::AguinaldoCalculator.new(
      monthly_gross_salary: payroll_profile.base_salary,
      hire_date: payroll_profile.hire_date
    ).call
  end

  def calculate_savings_fund(payroll_profile)
    Payroll::SavingsFundCalculator.new(
      monthly_gross_salary: payroll_profile.base_salary,
      savings_fund_percentage: payroll_profile.savings_fund_rate
    ).call
  end
end
