# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/dashboard', type: :request do
  let(:user) { create(:user) }

  describe 'GET /' do
    context 'sin autenticación' do
      it 'redirige al login' do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'con usuario autenticado' do
      before do
        sign_in user
        presenter = instance_double(DashboardPresenter,
                                    available_balance: 0,
                                    available_balance_formatted: '$0.00',
                                    balance_breakdown: {
                                      cash: 0, cash_formatted: '$0.00',
                                      debit: 0, debit_formatted: '$0.00',
                                      debit_detail: [],
                                      savings: 0, savings_formatted: '$0.00',
                                      savings_detail: []
                                    },
                                    upcoming_card_due_dates: [],
                                    credit_utilization_alerts: [],
                                    total_debt: 0,
                                    total_debt_formatted: '$0.00',
                                    debt_breakdown: [],
                                    credit_cards?: false,
                                    savings_funds?: false,
                                    debit_cards?: false,
                                    saving_goals?: false)
        allow(DashboardPresenter).to receive(:new).with(user).and_return(presenter)
      end

      it 'retorna HTTP 200' do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /dashboard' do
    context 'sin autenticación' do
      it 'redirige al login' do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'con usuario autenticado' do
      before do
        sign_in user
        presenter = instance_double(DashboardPresenter,
                                    available_balance: 5_000,
                                    available_balance_formatted: '$5,000.00',
                                    balance_breakdown: {
                                      cash: 5_000, cash_formatted: '$5,000.00',
                                      debit: 0, debit_formatted: '$0.00',
                                      debit_detail: [],
                                      savings: 0, savings_formatted: '$0.00',
                                      savings_detail: []
                                    },
                                    upcoming_card_due_dates: [],
                                    credit_utilization_alerts: [],
                                    total_debt: 0,
                                    total_debt_formatted: '$0.00',
                                    debt_breakdown: [],
                                    credit_cards?: false,
                                    savings_funds?: false,
                                    debit_cards?: false,
                                    saving_goals?: false)
        allow(DashboardPresenter).to receive(:new).with(user).and_return(presenter)
      end

      it 'retorna HTTP 200' do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
