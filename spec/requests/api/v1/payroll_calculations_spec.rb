# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/payroll_calculations', type: :request do
  let(:user) { create(:user) }
  let!(:payroll_profile) { create(:payroll_profile, user:) }

  before { sign_in user }

  describe 'GET /api/v1/payroll_calculations/aguinaldo' do
    context 'cuando el usuario tiene perfil de nómina' do
      it 'retorna HTTP 200' do
        get aguinaldo_api_v1_payroll_calculations_path
        expect(response).to have_http_status(:ok)
      end

      it 'retorna JSON con estructura correcta' do
        get aguinaldo_api_v1_payroll_calculations_path
        json = response.parsed_body
        expect(json['record']).to include('amount', 'days_worked', 'proportional')
      end

      it 'retorna aguinaldo no proporcional para 2 años de antigüedad' do
        get aguinaldo_api_v1_payroll_calculations_path
        json = response.parsed_body
        expect(json['record']['proportional']).to be(false)
      end
    end

    context 'cuando el usuario no tiene perfil de nómina' do
      let!(:payroll_profile) { nil }

      before { user.payroll_profile&.destroy }

      it 'retorna HTTP 404' do
        get aguinaldo_api_v1_payroll_calculations_path
        expect(response).to have_http_status(:not_found)
      end

      it 'retorna mensaje de error' do
        get aguinaldo_api_v1_payroll_calculations_path
        json = response.parsed_body
        expect(json['error']['code']).to eq('not_found')
      end
    end

    context 'sin autenticación' do
      before { sign_out user }

      it 'redirige al login' do
        get aguinaldo_api_v1_payroll_calculations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /api/v1/payroll_calculations/savings_fund' do
    it 'retorna HTTP 200' do
      get savings_fund_api_v1_payroll_calculations_path
      expect(response).to have_http_status(:ok)
    end

    it 'retorna JSON con estructura correcta' do
      get savings_fund_api_v1_payroll_calculations_path
      json = response.parsed_body
      expect(json['record']).to include(
        'employee_contribution', 'employer_contribution', 'monthly_total', 'uma_cap_applied'
      )
    end

    context 'CA2: calcula fondo de ahorro al 4% sobre base_salary' do
      let!(:payroll_profile) { create(:payroll_profile, user:, base_salary: 20_000, savings_fund_rate: 4.0) }

      it 'aplica 4% sobre sueldo base ($800)' do
        get savings_fund_api_v1_payroll_calculations_path
        json = response.parsed_body
        expect(json['record']['employee_contribution'].to_f).to eq(800.0)
        expect(json['record']['employer_contribution'].to_f).to eq(800.0)
      end
    end

    context 'con salario y tasa que excede tope UMA' do
      let!(:payroll_profile) { create(:payroll_profile, :high_salary, user:) }

      it 'indica que se aplicó el tope UMA' do
        get savings_fund_api_v1_payroll_calculations_path
        json = response.parsed_body
        expect(json['record']['uma_cap_applied']).to be(true)
      end
    end
  end

  describe 'GET /api/v1/payroll_calculations/net_salary' do
    it 'retorna HTTP 200' do
      get net_salary_api_v1_payroll_calculations_path
      expect(response).to have_http_status(:ok)
    end

    it 'retorna JSON con estructura correcta' do
      get net_salary_api_v1_payroll_calculations_path
      json = response.parsed_body
      expect(json['record']).to include(
        'base_salary', 'total_bonuses', 'savings_fund_employee', 'savings_fund_employer',
        'isr_estimated', 'imss_estimated', 'net_salary'
      )
    end

    it 'el salario neto es menor que el sueldo base' do
      get net_salary_api_v1_payroll_calculations_path
      json = response.parsed_body
      net = json['record']['net_salary'].to_f
      base = json['record']['base_salary'].to_f
      expect(net).to be < base
    end

    context 'CA4: $20,000 base + $2,000 bonos con tasas personalizadas' do
      let!(:payroll_profile) do
        create(:payroll_profile, :custom_rates,
               user:,
               base_salary: 20_000,
               non_taxable_bonuses: { 'transporte' => 2000 },
               savings_fund_rate: 4.0)
      end

      it 'calcula neto de $16,880' do
        get net_salary_api_v1_payroll_calculations_path
        json = response.parsed_body
        expect(json['record']['net_salary'].to_f).to eq(16_880.0)
      end
    end
  end
end
