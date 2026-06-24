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

    context 'CA3: con usuario autenticado sin nómina ni presupuesto configurados' do
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
                                    saving_goals?: false,
                                    next_payroll_info: nil,
                                    payroll_configured?: false,
                                    monthly_budget_summary: [],
                                    monthly_budget_summary?: false,
                                    prioritized_saving_goals: [])
        allow(DashboardPresenter).to receive(:new).with(user).and_return(presenter)
      end

      it 'retorna HTTP 200' do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it 'CA3: muestra mensaje de onboarding para nómina' do
        get root_path
        expect(response.body).to include('Configurar información laboral')
      end

      it 'CA5: muestra mensaje de onboarding para presupuesto' do
        get root_path
        expect(response.body).to include('Sin gastos registrados este mes')
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

    context 'CA1: con usuario autenticado con datos de nómina y presupuesto' do
      let(:payroll_info) do
        { net_amount: 25_000.0, net_amount_formatted: '$25,000.00',
          payment_date: Date.current + 10, days_until: 10, coming_soon: false }
      end
      let(:budget_items) do
        [{ category_name: 'Alimentación', amount: 5_000.0, amount_formatted: '$5,000.00',
           progress_percent: 100, status: :danger },
         { category_name: 'Transporte', amount: 2_000.0, amount_formatted: '$2,000.00',
           progress_percent: 40, status: :safe }]
      end

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
                                    saving_goals?: false,
                                    next_payroll_info: payroll_info,
                                    payroll_configured?: true,
                                    monthly_budget_summary: budget_items,
                                    monthly_budget_summary?: true,
                                    prioritized_saving_goals: [])
        allow(DashboardPresenter).to receive(:new).with(user).and_return(presenter)
      end

      it 'CA1: retorna HTTP 200' do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it 'CA2: muestra monto de nómina' do
        get dashboard_path
        expect(response.body).to include('$25,000.00')
      end

      it 'CA4: muestra categorías de presupuesto' do
        get dashboard_path
        expect(response.body).to include('Alimentación')
        expect(response.body).to include('Transporte')
      end
    end

    context 'CA8: con nómina próxima en menos de 7 días' do
      let(:payroll_soon) do
        { net_amount: 20_000.0, net_amount_formatted: '$20,000.00',
          payment_date: Date.current + 3, days_until: 3, coming_soon: true }
      end

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
                                    saving_goals?: false,
                                    next_payroll_info: payroll_soon,
                                    payroll_configured?: true,
                                    monthly_budget_summary: [],
                                    monthly_budget_summary?: false,
                                    prioritized_saving_goals: [])
        allow(DashboardPresenter).to receive(:new).with(user).and_return(presenter)
      end

      it 'CA8: muestra badge Próximamente' do
        get dashboard_path
        expect(response.body).to include('Próximamente')
      end
    end
  end

  describe 'GET /dashboard/saving_goals_recalculate' do
    context 'sin autenticación' do
      it 'retorna 401' do
        get dashboard_saving_goals_recalculate_path(format: :json)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'con usuario autenticado y sin metas activas' do
      before { sign_in user }

      it 'retorna HTTP 200 con lista vacía' do
        get dashboard_saving_goals_recalculate_path(format: :json)
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['goals']).to eq([])
      end
    end

    context 'con usuario autenticado y metas activas' do
      let(:saving_goal) { create(:saving_goal, user:, target_amount: 10_000) }

      before do
        sign_in user
        goal = saving_goal
        presenter = instance_double(
          DashboardPresenter,
          prioritized_saving_goals: [
            {
              saving_goal: goal,
              allocated_amount: 5_000,
              allocated_formatted: '$5,000.00',
              target_amount: 10_000,
              target_formatted: '$10,000.00',
              progress_percentage: 50.0
            }
          ]
        )
        allow(DashboardPresenter).to receive(:new).with(user).and_return(presenter)
      end

      it 'retorna JSON con metas y montos asignados' do
        get dashboard_saving_goals_recalculate_path(format: :json)
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['goals'].size).to eq(1)
        expect(body['goals'].first['id']).to eq(saving_goal.id)
        expect(body['goals'].first['allocated_amount']).to eq(5_000)
        expect(body['goals'].first['percentage']).to eq(50.0)
      end
    end
  end
end
