# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardSerializer do
  let(:user) { create(:user) }
  let(:category) { category_for('Comida') }

  before { allow(AiReport).to receive(:latest_for_user_and_type).and_return(nil) }

  def build_ai_report(summary:, created_at:)
    report_type = Catalog.new(code: 'general')
    AiReport.new(report_type:, processing_success: true,
                 parsed_insights: { 'summary' => summary }, created_at:)
  end

  describe '#as_json' do
    it 'incluye las 5 secciones del dashboard' do
      json = described_class.new(user).as_json

      expect(json.keys).to contain_exactly(
        :financial_summary, :upcoming_payments, :credit_cards, :latest_ai_insight, :budgets_summary
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
        id: cercano.id, description: cercano.name, amount: 200.0,
        payment_due_date: Date.current + 5.days, days_until_due: 5, category: 'Servicios'
      )
      expect(result.map { |p| p[:payment_due_date] }).to eq(result.map { |p| p[:payment_due_date] }.sort)
    end
  end

  describe 'credit_cards' do
    it 'CA4: retorna tarjetas ordenadas por cutting_date con calculated_balance' do
      card_a = make_credit_card(user:, limit_amount: 10_000, name: 'Tarjeta A', cutting_day: 25)
      card_b = make_credit_card(user:, limit_amount: 5_000, name: 'Tarjeta B', cutting_day: 1)
      expected_order = [card_a, card_b].sort_by(&:next_cutting_date).map(&:id)

      result = described_class.new(user).as_json[:credit_cards]

      expect(result.map { |c| c[:id] }).to eq(expected_order)
      expect(result).to all(include(:id, :name, :calculated_balance, :cutting_date, :payment_due_date))
    end
  end

  describe 'latest_ai_insight' do
    it 'CA3: retorna el reporte cacheado cuando existe uno exitoso' do
      created_at = Time.zone.parse('2026-09-01 10:00:00')
      report = build_ai_report(summary: { 'text' => 'ok' }, created_at:)
      allow(AiReport).to receive(:latest_for_user_and_type).with(user.id, 'general').and_return(report)

      result = described_class.new(user).as_json[:latest_ai_insight]

      expect(result).to eq(
        summary: { 'text' => 'ok' }, generated_at: created_at.iso8601, report_type: 'general'
      )
    end

    it 'retorna nil cuando no hay reporte o no fue exitoso' do
      result = described_class.new(user).as_json[:latest_ai_insight]

      expect(result).to be_nil
    end
  end

  describe 'budgets_summary' do
    it 'CA6: calcula total_budgeted, total_spent, percentage_used y active_count del mes actual' do
      budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
      make_transaction(user:, budget:, category:, amount: 300, type_code: 'expense')

      result = described_class.new(user).as_json[:budgets_summary]

      expect(result).to eq(
        total_budgeted: 700.0, total_spent: 300.0, percentage_used: 42.86, active_count: 1
      )
    end

    it 'no divide por cero cuando no hay presupuesto asignado' do
      make_budget(user:, type_code: 'cash', amount: 0, personal: true)

      result = described_class.new(user).as_json[:budgets_summary]

      expect(result[:percentage_used]).to eq(0.0)
    end
  end
end
