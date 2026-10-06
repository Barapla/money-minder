# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardSerializer do
  let(:user) { create(:user) }
  let(:category) { category_for('Comida') }

  before { allow(AiReport).to receive(:latest_stored).and_return(nil) }

  def build_ai_report(summary:, created_at:, id: 1, expires_at: nil)
    report_type = Catalog.new(code: 'general')
    AiReport.new(id:, report_type:, processing_success: true,
                 parsed_insights: { 'summary' => summary }, created_at:, expires_at:)
  end

  describe '#as_json' do
    it 'incluye las 8 secciones del dashboard' do
      json = described_class.new(user).as_json

      expect(json.keys).to contain_exactly(
        :financial_summary, :trend_data, :upcoming_payments, :active_budgets,
        :credit_cards_summary, :savings_summary, :recent_transactions, :latest_insight
      )
    end
  end

  describe 'financial_summary' do
    it 'calcula ingresos, gastos y balance del mes actual' do
      budget = make_budget(user:, type_code: 'cash', amount: 0, personal: true)
      make_transaction(user:, budget:, category:, amount: 1000, type_code: 'income')
      make_transaction(user:, budget:, category:, amount: 300, type_code: 'expense')

      result = described_class.new(user).as_json[:financial_summary]

      expect(result[:total_income]).to eq(1000.0)
      expect(result[:total_expenses]).to eq(300.0)
      expect(result[:balance]).to eq(700.0)
      expect(result[:month]).to eq(Date.current.month)
      expect(result[:year]).to eq(Date.current.year)
    end
  end

  describe 'trend_data' do
    it 'retorna 6 meses con el mes actual al final' do
      result = described_class.new(user).as_json[:trend_data]

      expect(result.length).to eq(6)
      expect(result.last[:month]).to eq(Date.current.strftime('%Y-%m'))
    end
  end

  describe 'upcoming_payments' do
    it 'CA2: retorna array vacio cuando no hay pagos obligatorios pendientes' do
      result = described_class.new(user).as_json[:upcoming_payments]

      expect(result).to eq([])
    end

    it 'ordena por fecha de vencimiento y excluye fuera de la ventana de 30 dias' do
      make_obligatory_payment(user:, amount: 100, due_date: Date.current + 20.days)
      lejano = make_obligatory_payment(user:, amount: 999, due_date: Date.current + 60.days)
      cercano = make_obligatory_payment(user:, amount: 200, due_date: Date.current + 5.days)

      result = described_class.new(user).as_json[:upcoming_payments]

      expect(result.map { |p| p[:id] }).not_to include(lejano.id)
      expect(result.first).to include(
        id: cercano.id, title: cercano.name, amount: 200.0,
        due_date: Date.current + 5.days, category: 'Servicios'
      )
      expect(result.map { |p| p[:due_date] }).to eq(result.map { |p| p[:due_date] }.sort)
    end
  end

  describe 'active_budgets' do
    it 'CA4/6: calcula el progreso de cada presupuesto activo del mes actual' do
      budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
      make_transaction(user:, budget:, category:, amount: 300, type_code: 'expense')

      result = described_class.new(user).as_json[:active_budgets]

      expect(result).to eq(
        [{ budget_id: budget.id, category_name: budget.name, category_color: 'Purple', budget_type: 'cash',
           debt_amount: 0.0, limit_amount: 0.0, available_amount: 700.0, spent_this_month: 300.0,
           percentage_used: 0.0 }]
      )
    end

    it 'no divide por cero cuando no hay presupuesto asignado' do
      make_budget(user:, type_code: 'cash', amount: 0, personal: true)

      result = described_class.new(user).as_json[:active_budgets]

      expect(result.first[:percentage_used]).to eq(0.0)
    end
  end

  describe 'credit_cards_summary' do
    it 'CA4: retorna tarjetas ordenadas por cutting_date' do
      card_a = make_credit_card(user:, limit_amount: 10_000, name: 'Tarjeta A', cutting_day: 25)
      card_b = make_credit_card(user:, limit_amount: 5_000, name: 'Tarjeta B', cutting_day: 1)
      expected_order = [card_a, card_b].sort_by(&:next_cutting_date).map(&:id)

      result = described_class.new(user).as_json[:credit_cards_summary]

      expect(result.map { |c| c[:card_id] }).to eq(expected_order)
      expect(result).to all(
        include(:card_id, :card_name, :current_balance, :credit_limit, :available_credit,
                :next_cutting_date, :next_payment_date)
      )
    end
  end

  describe 'savings_summary' do
    it 'retorna el progreso de cada fondo de ahorro activo' do
      fund = make_savings_fund(user:, goal_amount: 20_000, current_amount: 5_000, name: 'Fondo Emergencia')

      result = described_class.new(user).as_json[:savings_summary]

      expect(result).to eq(
        [{ fund_id: fund.id, fund_name: 'Fondo Emergencia', current_amount: 5000.0,
           goal_amount: 20_000.0, percentage_achieved: 25.0,
           target_date: nil, feasibility: 'no_target_date' }]
      )
    end
  end

  describe 'recent_transactions' do
    it 'retorna las transacciones mas recientes ordenadas DESC' do
      budget = make_budget(user:, type_code: 'cash', amount: 0, personal: true)
      newer = make_transaction(user:, budget:, category:, amount: 200, type_code: 'expense',
                               transaction_date: Date.current)
      older = make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense',
                               transaction_date: 2.days.ago.to_date)

      result = described_class.new(user).as_json[:recent_transactions]

      expect(result.map { |t| t[:id] }).to eq([newer.id, older.id])
    end
  end

  describe 'latest_insight' do
    before { allow(AiReportGenerationJob).to receive(:enqueue_once) }

    it 'CA8: retorna el reporte cacheado cuando existe uno exitoso' do
      created_at = Time.zone.parse('2026-09-01 10:00:00')
      report = build_ai_report(summary: { 'text' => 'ok' }, created_at:, id: 9)
      allow(AiReport).to receive(:latest_stored).with(user.id, 'general').and_return(report)

      result = described_class.new(user).as_json[:latest_insight]

      expect(result).to eq(
        id: 9, content: { 'text' => 'ok' }, created_at: created_at.iso8601, expires_at: nil
      )
    end

    it 'retorna nil cuando no hay reporte o no fue exitoso' do
      result = described_class.new(user).as_json[:latest_insight]

      expect(result).to be_nil
    end

    it 'encola la generacion en segundo plano cuando no hay reporte, sin generarlo en el request' do
      allow(AiReport).to receive(:generate_new_report)

      described_class.new(user).as_json

      expect(AiReportGenerationJob).to have_received(:enqueue_once).with(user.id)
      expect(AiReport).not_to have_received(:generate_new_report)
    end

    it 'devuelve el reporte expirado y encola su regeneracion' do
      report = build_ai_report(summary: { 'text' => 'viejo' }, created_at: 2.days.ago, id: 3)
      report.expires_at = 1.day.ago
      allow(AiReport).to receive(:latest_stored).with(user.id, 'general').and_return(report)

      result = described_class.new(user).as_json[:latest_insight]

      expect(result[:content]).to eq('text' => 'viejo')
      expect(AiReportGenerationJob).to have_received(:enqueue_once).with(user.id)
    end

    it 'no encola nada si el reporte sigue vigente' do
      report = build_ai_report(summary: { 'text' => 'ok' }, created_at: Time.current, id: 4)
      allow(AiReport).to receive(:latest_stored).and_return(report)

      described_class.new(user).as_json

      expect(AiReportGenerationJob).not_to have_received(:enqueue_once)
    end
  end
end
