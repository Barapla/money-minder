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

  describe 'GET /api/v1/dashboard?period=... (FEAT-037)' do
    let(:budget) { make_budget(user:, type_code: 'cash', amount: 0, personal: true) }
    let(:category) { category_for('Comida') }

    context 'FEAT-037 CA1: period=month' do
      it 'incluye solo transacciones del mes calendario actual' do
        make_transaction(user:, budget:, category:, amount: 500, type_code: 'expense', transaction_date: Date.current)
        make_transaction(user:, budget:, category:, amount: 1000, type_code: 'expense',
                         transaction_date: 2.months.ago.to_date)

        get api_v1_dashboard_path, params: { period: 'month' }, headers: auth_headers

        expect(response.parsed_body['record']['financial_summary']['total_expenses']).to eq(500.0)
      end
    end

    context 'FEAT-037 CA2: period=30days' do
      it 'incluye solo transacciones de los ultimos 30 dias naturales' do
        make_transaction(user:, budget:, category:, amount: 200, type_code: 'expense',
                         transaction_date: 25.days.ago.to_date)
        make_transaction(user:, budget:, category:, amount: 900, type_code: 'expense',
                         transaction_date: 40.days.ago.to_date)

        get api_v1_dashboard_path, params: { period: '30days' }, headers: auth_headers

        expect(response.parsed_body['record']['financial_summary']['total_expenses']).to eq(200.0)
      end
    end

    context 'FEAT-037 CA3: period=year' do
      it 'incluye solo transacciones del año calendario actual' do
        make_transaction(user:, budget:, category:, amount: 300, type_code: 'expense',
                         transaction_date: Date.current.beginning_of_year)
        make_transaction(user:, budget:, category:, amount: 700, type_code: 'expense',
                         transaction_date: 1.year.ago.to_date)

        get api_v1_dashboard_path, params: { period: 'year' }, headers: auth_headers

        expect(response.parsed_body['record']['financial_summary']['total_expenses']).to eq(300.0)
      end
    end

    context 'FEAT-037 CA4: sin period param' do
      it 'usa month por defecto' do
        make_transaction(user:, budget:, category:, amount: 500, type_code: 'expense', transaction_date: Date.current)
        make_transaction(user:, budget:, category:, amount: 1000, type_code: 'expense',
                         transaction_date: 2.months.ago.to_date)

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['financial_summary']['total_expenses']).to eq(500.0)
      end
    end

    context 'FEAT-037 CA5: period=invalid' do
      it 'retorna 400 con mensaje de periodos permitidos' do
        get api_v1_dashboard_path, params: { period: 'invalid' }, headers: auth_headers

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body.dig('error', 'code')).to eq('invalid_period')
        expect(response.parsed_body.dig('error', 'message')).to eq('Invalid period. Allowed: month, 30days, year')
      end
    end

    context 'FEAT-037 CA6: category_breakdown' do
      it 'retorna categorias ordenadas por amount DESC con category_name, amount y percentage' do
        make_transaction(user:, budget:, category:, amount: 600, type_code: 'expense')
        make_transaction(user:, budget:, category: category_for('Transporte'), amount: 400, type_code: 'expense')
        make_transaction(user:, budget:, category:, amount: 5000, type_code: 'income')

        get api_v1_dashboard_path, headers: auth_headers

        breakdown = response.parsed_body['record']['financial_summary']['category_breakdown']
        expect(breakdown).to eq(
          [
            { 'category_name' => 'Comida', 'amount' => 600.0, 'percentage' => 60.0 },
            { 'category_name' => 'Transporte', 'amount' => 400.0, 'percentage' => 40.0 }
          ]
        )
      end
    end

    context 'FEAT-037 CA7: transacciones sin categoria' do
      it "expone la entrada 'Sin categoría' que retorna CategoryBreakdownCalculator" do
        fake_breakdown = [{ category_name: 'Sin categoría', amount: 500.0, percentage: 100.0 }]
        allow(CategoryBreakdownCalculator).to receive(:new)
          .and_return(instance_double(CategoryBreakdownCalculator, call: fake_breakdown))

        get api_v1_dashboard_path, headers: auth_headers

        breakdown = response.parsed_body['record']['financial_summary']['category_breakdown']
        expect(breakdown).to eq([{ 'category_name' => 'Sin categoría', 'amount' => 500.0, 'percentage' => 100.0 }])
      end
    end

    context 'FEAT-037 CA8: porcentajes' do
      it 'suman 100.0 cuando hay gastos y 0 (array vacio) cuando no hay gastos' do
        make_transaction(user:, budget:, category:, amount: 600, type_code: 'expense')
        make_transaction(user:, budget:, category: category_for('Transporte'), amount: 400, type_code: 'expense')

        get api_v1_dashboard_path, headers: auth_headers
        breakdown = response.parsed_body['record']['financial_summary']['category_breakdown']

        expect(breakdown.sum { |item| item['percentage'] }).to eq(100.0)

        other_user = create(:user)
        other_token = other_user.generate_jwt_token[:token]
        get api_v1_dashboard_path, headers: { 'Authorization' => "Bearer #{other_token}" }

        expect(response.parsed_body['record']['financial_summary']['category_breakdown']).to eq([])
      end
    end
  end
end
