# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /budgets/:id (tarjeta de crédito)', type: :request do
  include FinancialTestHelpers

  let(:user) { create(:user) }
  let(:card) { make_credit_card(user:, limit_amount: 21_000, name: 'Klar', cutting_day: 7) }
  let(:budget) { card.budget }

  before { sign_in user }

  context 'sin movimientos' do
    it 'renderiza la vista de tarjeta sin traducciones faltantes' do
      get budget_path(budget)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Saldo del ciclo en curso')
      expect(response.body).not_to include('translation missing')
    end

    it 'muestra el límite y el techo sano del 30%' do
      get budget_path(budget)

      expect(response.body).to include('$21,000.00')
      expect(response.body).to include('$6,300.00')
    end

    it 'muestra el estado vacío de movimientos' do
      get budget_path(budget)
      expect(response.body).to include('Sin movimientos en este ciclo')
    end
  end

  context 'con compras en el ciclo en curso' do
    before do
      make_transaction(user:, budget:, category: category_for('Internet y teléfono'),
                       amount: 2_172.59, type_code: 'expense', transaction_date: Date.current)
      make_transaction(user:, budget:, category: category_for('Internet y teléfono'),
                       amount: 1_154.03, type_code: 'expense', transaction_date: Date.current)
    end

    it 'suma las compras en el saldo del ciclo' do
      get budget_path(budget)
      expect(response.body).to include('$3,326.62')
    end

    it 'lista los movimientos del ciclo con su categoría' do
      get budget_path(budget)
      expect(response.body).to include('Internet y teléfono')
    end

    it 'calcula el pago mínimo como 5% del saldo' do
      get budget_path(budget)
      expect(response.body).to include('$166.33')
    end

    it 'muestra el crédito disponible restante' do
      get budget_path(budget)
      expect(response.body).to include('$17,673.38')
    end

    it 'muestra la columna de arrastre con la fórmula del cierre' do
      get budget_path(budget)
      expect(response.body).to include('Arrastre')
      expect(response.body).to include('Cierre = arrastre + compras − pagos')
    end

    it 'muestra la columna de uso al corte y etiqueta el donut como proyección' do
      get budget_path(budget)
      expect(response.body).to include('Uso al corte')
      expect(response.body).to include('proyectada al corte')
    end
  end

  context 'otros tipos de presupuesto' do
    let(:cash_budget) { make_budget(user:, type_code: 'cash', amount: 500, name: 'Efectivo') }

    it 'sigue usando la vista genérica' do
      get budget_path(cash_budget)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Saldo del ciclo en curso')
    end
  end
end
