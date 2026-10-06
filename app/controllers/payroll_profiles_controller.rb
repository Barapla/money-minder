# frozen_string_literal: true

# Permite editar la configuracion de nomina: bonos no gravados y tasas de deduccion.
class PayrollProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payroll_profile

  def edit; end

  def update
    if @payroll_profile.update(payroll_profile_params)
      redirect_to employment_information_path, notice: t('payroll_profiles.update.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_payroll_profile
    @payroll_profile = current_user.payroll_profile
    return if @payroll_profile.present?

    redirect_to new_employment_information_path, alert: t('payroll_profiles.set_payroll_profile.not_found')
  end

  def payroll_profile_params
    permitted = params.require(:payroll_profile).permit(
      :savings_fund_rate, :custom_isr_rate, :custom_imss_rate,
      bonus_names: [], bonus_amounts: []
    )

    build_attrs(permitted)
  end

  def build_attrs(permitted)
    names = Array(permitted.delete(:bonus_names)).map(&:strip)
    amounts = Array(permitted.delete(:bonus_amounts))

    bonuses = names.zip(amounts).each_with_object({}) do |(name, amount), hash|
      hash[name] = amount.to_f if name.present? && amount.present?
    end

    permitted.merge(non_taxable_bonuses: bonuses)
  end
end
