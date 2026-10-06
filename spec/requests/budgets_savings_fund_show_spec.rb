# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /budgets/:id (fondo de ahorro)', type: :request do
  include FinancialTestHelpers

  let(:user) { create(:user) }
  let!(:fund) do
    make_savings_fund(user:, goal_amount: 25_000, current_amount: 25_507.64, name: 'Klar (Sofipo)')
  end
  let(:budget) { fund.budget }

  before do
    fund.update!(interest_rate: 15.0)
    sign_in user
  end

  it 'renderiza la vista de fondo sin traducciones faltantes' do
    get budget_path(budget)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Saldo del fondo')
    expect(response.body).not_to include('translation missing')
  end

  it 'muestra el saldo y la tasa configurada' do
    get budget_path(budget)

    expect(response.body).to include('$25,507.64')
    expect(response.body).to include('15%')
  end

  it 'muestra el progreso contra la meta' do
    get budget_path(budget)

    expect(response.body).to include('Meta alcanzada')
  end

  it 'no usa la vista genérica ni la de tarjeta' do
    get budget_path(budget)

    expect(response.body).not_to include('Saldo del ciclo en curso')
    expect(response.body).not_to include('Evolución del Saldo')
  end

  context 'con varios fondos' do
    let!(:other) do
      make_savings_fund(user:, goal_amount: 10_000, current_amount: 10_234.47, name: 'Didi Cuenta')
        .tap { |f| f.update!(interest_rate: 12.0) }
    end

    it 'calcula el peso del fondo dentro del total' do
      get budget_path(budget)

      # 25.507,64 de 35.742,11 = 71.4%
      expect(response.body).to include('71.4%')
      expect(response.body).to include('Tu fondo más grande')
    end

    it 'sugiere mover el saldo del fondo con menor tasa' do
      get budget_path(budget)

      expect(response.body).to include('Didi Cuenta')
      expect(response.body).to include('rinde menos')
    end
  end

  context 'sin meta configurada' do
    before { fund.update!(goal_amount: 0) }

    it 'no revienta y avisa que falta la meta' do
      get budget_path(budget)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('sin meta configurada')
    end
  end
end
