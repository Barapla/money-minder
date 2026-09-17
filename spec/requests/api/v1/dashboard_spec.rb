# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/dashboard', type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_jwt_token[:token] }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  before { allow(AiReport).to receive(:latest_for_user_and_type).and_return(nil) }

  def build_ai_report(summary:, created_at:, id: 1, expires_at: nil)
    report_type = Catalog.new(code: 'general')
    AiReport.new(id:, report_type:, processing_success: true,
                 parsed_insights: { 'summary' => summary }, created_at:, expires_at:)
  end

  describe 'GET /api/v1/dashboard' do
    context 'CA1: con token JWT valido' do
      it 'retorna HTTP 200 con la estructura consolidada del dashboard' do
        get api_v1_dashboard_path, headers: auth_headers

        expect(response).to have_http_status(:ok)
        record = response.parsed_body['record']
        expect(record.keys).to contain_exactly(
          'financial_summary', 'trend_data', 'upcoming_payments', 'active_budgets',
          'credit_cards_summary', 'savings_summary', 'recent_transactions', 'latest_insight'
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
      it 'retorna latest_insight con id, content, created_at y expires_at' do
        created_at = Time.zone.parse('2026-09-01 10:00:00')
        expires_at = Time.zone.parse('2026-09-01 10:15:00')
        report = build_ai_report(summary: { 'text' => 'ok' }, created_at:, id: 7, expires_at:)
        allow(AiReport).to receive(:latest_for_user_and_type).with(user.id, 'general').and_return(report)

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['latest_insight']).to eq(
          'id' => 7, 'content' => { 'text' => 'ok' },
          'created_at' => created_at.iso8601, 'expires_at' => expires_at.iso8601
        )
      end
    end

    context 'CA4: con multiples tarjetas de credito' do
      it 'retorna credit_cards_summary ordenadas por cutting_date' do
        card_a = make_credit_card(user:, limit_amount: 10_000, name: 'Tarjeta A', cutting_day: 25)
        card_b = make_credit_card(user:, limit_amount: 5_000, name: 'Tarjeta B', cutting_day: 1)
        expected_order = [card_a, card_b].sort_by(&:next_cutting_date).map(&:id)

        get api_v1_dashboard_path, headers: auth_headers

        cards = response.parsed_body['record']['credit_cards_summary']
        expect(cards.map { |c| c['card_id'] }).to eq(expected_order)
        expect(cards.first).to include(
          'card_id', 'card_name', 'current_balance', 'credit_limit', 'available_credit',
          'next_cutting_date', 'next_payment_date'
        )
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
      it 'retorna active_budgets con el progreso de cada presupuesto' do
        budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
        make_transaction(user:, budget:, category: category_for('Comida'), amount: 300, type_code: 'expense')

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['active_budgets']).to eq(
          [{ 'budget_id' => budget.id, 'category_name' => budget.name, 'category_color' => 'Purple',
             'budget_type' => 'cash', 'debt_amount' => 0.0, 'limit_amount' => 0.0,
             'available_amount' => 700.0, 'spent_this_month' => 300.0, 'percentage_used' => 0.0 }]
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
        expect(record['credit_cards_summary']).to eq([])
      end
    end
  end

  describe 'GET /api/v1/dashboard (FEAT-038)' do
    context 'FEAT-038 CA2: trend_data' do
      it 'retorna 6 meses ordenados cronologicamente con month, income, expenses y balance' do
        budget = make_budget(user:, type_code: 'cash', amount: 0, personal: true)
        category = category_for('Comida')
        make_transaction(user:, budget:, category:, amount: 1000, type_code: 'income',
                         transaction_date: Date.current)
        make_transaction(user:, budget:, category:, amount: 400, type_code: 'expense',
                         transaction_date: Date.current)

        get api_v1_dashboard_path, headers: auth_headers

        trend = response.parsed_body['record']['trend_data']
        expect(trend.length).to eq(6)
        expect(trend.map { |t| t['month'] }).to eq(trend.map { |t| t['month'] }.sort)
        current_month = trend.last
        expect(current_month).to eq(
          'month' => Date.current.strftime('%Y-%m'), 'income' => 1000.0, 'expenses' => 400.0, 'balance' => 600.0
        )
      end
    end

    context 'FEAT-038 CA3: upcoming_payments con formato nuevo' do
      it 'incluye id, title, amount, currency, due_date y category' do
        payment = make_obligatory_payment(user:, amount: 750, due_date: Date.current + 5.days)

        get api_v1_dashboard_path, headers: auth_headers

        entry = response.parsed_body['record']['upcoming_payments'].first
        expect(entry).to include(
          'id' => payment.id, 'title' => payment.name, 'amount' => 750.0,
          'currency' => user.currency&.code, 'due_date' => (Date.current + 5.days).to_s,
          'category' => payment.category.name
        )
      end
    end

    context 'FEAT-038 CA6: con fondos de ahorro activos' do
      it 'retorna savings_summary con fund_id, fund_name, current_amount, goal_amount y percentage_achieved' do
        fund = make_savings_fund(user:, goal_amount: 20_000, current_amount: 5_000, name: 'Fondo Emergencia')

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['savings_summary']).to eq(
          [{ 'fund_id' => fund.id, 'fund_name' => 'Fondo Emergencia', 'current_amount' => 5000.0,
             'goal_amount' => 20_000.0, 'percentage_achieved' => 25.0,
             'target_date' => nil, 'feasibility' => 'no_target_date' }]
        )
      end
    end

    context 'FEAT-038 CA7: recent_transactions' do
      it 'retorna maximo 10 transacciones ordenadas por transaction_date DESC' do
        budget = make_budget(user:, type_code: 'cash', amount: 0, personal: true)
        category = category_for('Comida')
        older = make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense',
                                 transaction_date: 2.days.ago.to_date)
        newer = make_transaction(user:, budget:, category:, amount: 200, type_code: 'expense',
                                 transaction_date: Date.current)

        get api_v1_dashboard_path, headers: auth_headers

        transactions = response.parsed_body['record']['recent_transactions']
        expect(transactions.map { |t| t['id'] }).to eq([newer.id, older.id])
        expect(transactions.first).to include(
          'id', 'description', 'amount', 'currency', 'transaction_date',
          'category_name', 'category_color', 'transaction_type'
        )
      end

      it 'limita a las 10 mas recientes cuando hay mas' do
        budget = make_budget(user:, type_code: 'cash', amount: 0, personal: true)
        category = category_for('Comida')
        12.times do |i|
          make_transaction(user:, budget:, category:, amount: 10, type_code: 'expense',
                           transaction_date: i.days.ago.to_date)
        end

        get api_v1_dashboard_path, headers: auth_headers

        expect(response.parsed_body['record']['recent_transactions'].length).to eq(10)
      end
    end

    context 'FEAT-038 CA9: usuario sin datos financieros' do
      it 'retorna la estructura completa con arrays vacios y valores en cero' do
        get api_v1_dashboard_path, headers: auth_headers

        record = response.parsed_body['record']
        expect(record['upcoming_payments']).to eq([])
        expect(record['active_budgets']).to eq([])
        expect(record['credit_cards_summary']).to eq([])
        expect(record['savings_summary']).to eq([])
        expect(record['recent_transactions']).to eq([])
        expect(record['latest_insight']).to be_nil
        expect(record['financial_summary']['total_income']).to eq(0.0)
        expect(record['financial_summary']['total_expenses']).to eq(0.0)
        expect(record['trend_data'].length).to eq(6)
        expect(record['trend_data']).to all(include('income' => 0.0, 'expenses' => 0.0, 'balance' => 0.0))
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
