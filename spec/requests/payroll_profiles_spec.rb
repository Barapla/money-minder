# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/payroll_profile', type: :request do
  let(:user) { create(:user) }
  let!(:payroll_profile) { create(:payroll_profile, user:) }

  before { sign_in user }

  describe 'GET /payroll_profile/edit' do
    it 'retorna HTTP 200' do
      get edit_payroll_profile_path
      expect(response).to have_http_status(:ok)
    end

    context 'sin perfil de nomina' do
      let(:user) { create(:user) }
      let!(:payroll_profile) { nil }

      it 'redirige a nueva informacion laboral' do
        get edit_payroll_profile_path
        expect(response).to redirect_to(new_employment_information_path)
      end
    end

    context 'sin autenticacion' do
      before { sign_out user }

      it 'redirige al login' do
        get edit_payroll_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /payroll_profile' do
    context 'con datos validos' do
      let(:params) do
        {
          payroll_profile: {
            savings_fund_rate: 5.0,
            custom_isr_rate: 20.0,
            custom_imss_rate: nil,
            bonus_names: %w[transporte vales],
            bonus_amounts: %w[1500 500]
          }
        }
      end

      it 'actualiza el perfil y redirige' do
        patch payroll_profile_path, params: params
        expect(response).to redirect_to(employment_information_path)
      end

      it 'guarda los bonos como hash' do
        patch payroll_profile_path, params: params
        expect(payroll_profile.reload.non_taxable_bonuses).to eq({ 'transporte' => 1500.0, 'vales' => 500.0 })
      end

      it 'actualiza la tasa del fondo de ahorro' do
        patch payroll_profile_path, params: params
        expect(payroll_profile.reload.savings_fund_rate).to eq(5.0)
      end

      it 'ignora bonos con nombre vacio' do
        params[:payroll_profile][:bonus_names] = ['transporte', '']
        params[:payroll_profile][:bonus_amounts] = %w[1500 200]
        patch payroll_profile_path, params: params
        expect(payroll_profile.reload.non_taxable_bonuses).to eq({ 'transporte' => 1500.0 })
      end

      it 'ignora bonos con monto vacio' do
        params[:payroll_profile][:bonus_names] = %w[transporte vales]
        params[:payroll_profile][:bonus_amounts] = ['1500', '']
        patch payroll_profile_path, params: params
        expect(payroll_profile.reload.non_taxable_bonuses).to eq({ 'transporte' => 1500.0 })
      end
    end

    context 'con tasa de fondo de ahorro invalida' do
      it 'renderiza el formulario de edicion con errores' do
        patch payroll_profile_path, params: {
          payroll_profile: { savings_fund_rate: 200, bonus_names: [], bonus_amounts: [] }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
