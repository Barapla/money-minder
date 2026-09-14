# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/dashboard', type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_jwt_token[:token] }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  before { allow(AiReport).to receive(:latest_for_user_and_type).and_return(nil) }

  def build_ai_report(summary:, created_at:)
    report_type = Catalog.new(code: 'general')
    AiReport.new(report_type:, processing_success: true,
                 parsed_insights: { 'summary' => summary }, created_at:)
  end

  describe 'GET /api/v1/dashboard' do
    context 'CA1: con token JWT valido' do
      it 'retorna HTTP 200 con la estructura consolidada del dashboard' do
        get api_v1_dashboard_path, headers: auth_headers

        expect(response).to have_http_status(:ok)
        record = response.parsed_body['record']
        expect(record.keys).to contain_exactly(
          'financial_summary', 'upcoming_payments', 'credit_cards', 'latest_ai_insight', 'budgets_summary'
        )
      end
    end

    context 'CA2: sin pagos obligatorios pendientes' do
      it 'retorna upcoming_payments como array vacio' do
        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['upcoming_payments']).to eq([])
      end
    end

    context 'CA3: con reporte AI generado' do
      it 'retorna latest_ai_insight con el reporte mas reciente' do
        created_at = Time.zone.parse('2026-09-01 10:00:00')
        report = build_ai_report(summary: { 'text' => 'ok' }, created_at:)
        allow(AiReport).to receive(:latest_for_user_and_type).with(user.id, 'general').and_return(report)

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['latest_ai_insight']).to eq(
          'summary' => { 'text' => 'ok' }, 'generated_at' => created_at.iso8601, 'report_type' => 'general'
        )
      end
    end

    context 'CA4: con multiples tarjetas de credito' do
      it 'retorna credit_cards ordenadas por cutting_date con calculated_balance' do
        card_a = make_credit_card(user:, limit_amount: 10_000, name: 'Tarjeta A', cutting_day: 25)
        card_b = make_credit_card(user:, limit_amount: 5_000, name: 'Tarjeta B', cutting_day: 1)
        expected_order = [card_a, card_b].sort_by(&:next_cutting_date).map(&:id)

        get api_v1_dashboard_path, headers: auth_headers

        cards = response.parsed_body['record']['credit_cards']
        expect(cards.map { |c| c['id'] }).to eq(expected_order)
        expect(cards.first).to include('id', 'name', 'calculated_balance', 'cutting_date', 'payment_due_date')
      end
    end

    context 'CA5: sin token' do
      it 'retorna HTTP 401' do
        get api_v1_dashboard_path

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Token inválido o expirado'])
      end
    end

    context 'CA5: con token invalido' do
      it 'retorna HTTP 401' do
        get api_v1_dashboard_path, headers: { 'Authorization' => 'Bearer token-invalido' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Token inválido o expirado'])
      end
    end

    context 'CA6: con presupuestos activos' do
      it 'retorna budgets_summary con total_budgeted, total_spent y percentage_used del mes actual' do
        budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
        make_transaction(user:, budget:, category: category_for('Comida'), amount: 300, type_code: 'expense')

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['budgets_summary']).to eq(
          'total_budgeted' => 700.0, 'total_spent' => 300.0, 'percentage_used' => 42.86, 'active_count' => 1
        )
      end
    end

    context 'CA7: aislamiento de datos por usuario' do
      it 'no incluye pagos obligatorios ni tarjetas de otro usuario' do
        other_user = create(:user)
        make_obligatory_payment(user: other_user, amount: 500, due_date: Date.current + 3.days)
        make_credit_card(user: other_user, limit_amount: 8_000, name: 'Tarjeta ajena', cutting_day: 10)
        own_payment = make_obligatory_payment(user:, amount: 100, due_date: Date.current + 3.days)

        get api_v1_dashboard_path, headers: auth_headers

        record = response.parsed_body['record']
        expect(record['upcoming_payments'].map { |p| p['id'] }).to eq([own_payment.id])
        expect(record['credit_cards']).to eq([])
      end
    end
  end
end
