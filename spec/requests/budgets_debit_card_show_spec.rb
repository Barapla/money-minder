# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /budgets/:id (cuenta de débito)', type: :request do
  include FinancialTestHelpers

  let(:user) { create(:user) }
  let!(:budget) { make_budget(user:, type_code: 'debit_card', amount: 10_234.47, name: 'Didi Cuenta') }

  before { sign_in user }

  def movement(amount, type_code, on: Date.current, category: 'Supermercado')
    make_transaction(user:, budget:, category: category_for(category), amount:,
                     type_code:, transaction_date: on)
  end

  it 'renderiza la vista de débito sin traducciones faltantes' do
    get budget_path(budget)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Saldo disponible hoy')
    expect(response.body).not_to include('translation missing')
  end

  it 'no usa la vista genérica ni la de tarjeta de crédito' do
    get budget_path(budget)

    expect(response.body).not_to include('Saldo del ciclo en curso')
    expect(response.body).not_to include('Evolución del Saldo')
  end

  context 'con movimientos del mes' do
    before do
      movement(13_651.63, 'income', on: Date.current.beginning_of_month, category: 'Nómina')
      movement(2_417.80, 'expense', category: 'Supermercado')
      movement(1_020.86, 'expense', category: 'Combustible')
    end

    it 'separa lo que entró de lo que salió' do
      get budget_path(budget)

      expect(response.body).to include('$13,651.63')
      expect(response.body).to include('$3,438.66')
    end

    it 'desglosa en qué se va el dinero de la cuenta' do
      get budget_path(budget)

      expect(response.body).to include('En qué se va el dinero de esta cuenta')
      expect(response.body).to include('Supermercado')
      expect(response.body).to include('Combustible')
    end

    it 'lista los movimientos recientes con su saldo' do
      get budget_path(budget)

      expect(response.body).to include('Movimientos recientes')
      expect(response.body).to include('saldo')
    end
  end

  context 'sin movimientos' do
    it 'avisa en vez de dibujar una gráfica vacía' do
      get budget_path(budget)

      expect(response.body).to include('Aún no hay saldo registrado este mes')
      expect(response.body).to include('Sin salidas registradas este mes')
    end
  end

  context 'con una tarjeta de crédito por pagar' do
    let!(:card) { make_credit_card(user:, limit_amount: 21_000, name: 'Klar', cutting_day: 7) }

    before do
      make_transaction(user:, budget: card.budget, category: category_for('Internet'),
                       amount: 3_326.62, type_code: 'expense', transaction_date: Date.current)
    end

    it 'muestra las salidas programadas y aclara que no están ligadas a esta cuenta' do
      get budget_path(budget)

      expect(response.body).to include('Salidas programadas')
      expect(response.body).to include('todavía no guarda desde qué cuenta pagas cada una')
    end
  end
end
