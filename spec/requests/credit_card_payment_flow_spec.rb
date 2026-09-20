# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pago de una tarjeta de crédito', type: :request do
  include FinancialTestHelpers

  let(:user) { create(:user) }
  let(:card) { make_credit_card(user:, limit_amount: 21_000, name: 'Klar', cutting_day: 7) }
  let(:budget) { card.budget }

  before do
    sign_in user
    # El catalogo de tipos viene de seeds; en specs hay que crearlo explicitamente.
    %w[expense income transfer].each { |code| transaction_type_for(code) }
  end

  describe 'GET /budgets/:id' do
    it 'ofrece pagar como transferencia hacia la tarjeta, no como ingreso suelto' do
      get budget_path(budget)

      expect(response.body).to include("transaction_type=transfer&amp;related_budget_id=#{budget.id}")
        .or include("related_budget_id=#{budget.id}&amp;transaction_type=transfer")
    end

    it 'deja el depósito directo como acción aparte' do
      get budget_path(budget)

      expect(response.body).to include('Depósito directo')
      expect(response.body).to include("budget_id=#{budget.id}&amp;transaction_type=income")
    end
  end

  describe 'GET /transactions/new con destino precargado' do
    let!(:fund) { make_savings_fund(user:, goal_amount: 50_000, current_amount: 8_000, name: 'Fondo Klar').budget }

    it 'precarga tipo, monto y destino' do
      get new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id, amount: 3_326.62)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('3326.62')
    end

    it 'muestra el select de presupuesto destino en una transferencia nueva' do
      get new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id)

      expect(response.body).to include('related_budget_id')
      expect(response.body).to include('¿A qué presupuesto entra el dinero?')
    end

    it 'ofrece el fondo de ahorro como origen posible' do
      get new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id)
      expect(response.body).to include(fund.name)
    end

    it 'no lista presupuestos de otros usuarios como destino' do
      otra = make_budget(user: create(:user), type_code: 'debit_card', amount: 100, name: 'Cuenta ajena')

      get new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id)

      expect(response.body).not_to include(otra.name)
    end
  end

  describe 'origen de una transferencia' do
    let(:fund) { make_savings_fund(user:, goal_amount: 50_000, current_amount: 8_000, name: 'Fondo Klar').budget }

    def build_transfer(origin, destination)
      Transaction.new(user:, budget: origin, related_budget: destination, amount: 100,
                      description: 'traspaso', category: category_for('Internet'),
                      transaction_type: transaction_type_for('transfer'),
                      color: color_catalog, icon: icon_catalog,
                      currency: Currency.default || create(:currency),
                      transaction_date: Date.current)
    end

    it 'rechaza que salga de una tarjeta de crédito con un mensaje claro' do
      transfer = build_transfer(budget, fund)

      expect(transfer).to be_invalid
      expect(transfer.errors[:budget_id].join).to include('no puede ser una tarjeta de crédito')
    end

    it 'no revienta con Unsupported transaction type al guardar' do
      expect { build_transfer(budget, fund).save }.not_to raise_error
    end

    it 'acepta que salga de un fondo de ahorro' do
      expect(build_transfer(fund, budget)).to be_valid
    end

    # Se compara por value del option: la tarjeta y el fondo comparten la palabra
    # "Klar" en el nombre, asi que buscar por texto daria falsos positivos.
    def origin_option_ids
      select_html = response.body[%r{id="transaction_budget_id".*?</select>}m].to_s
      select_html.scan(/value="(\d+)"/).flatten.map(&:to_i)
    end

    it 'no ofrece tarjetas de crédito en el select de origen de una transferencia' do
      fund
      get new_transaction_path(transaction_type: 'transfer', related_budget_id: budget.id)

      expect(origin_option_ids).to include(fund.id)
      expect(origin_option_ids).not_to include(budget.id)
    end

    it 'sí las ofrece cuando el movimiento es un gasto' do
      fund
      budget
      get new_transaction_path(transaction_type: 'expense')

      expect(origin_option_ids).to include(budget.id, fund.id)
    end
  end

  describe 'POST /transactions' do
    let(:fund) { make_savings_fund(user:, goal_amount: 50_000, current_amount: 8_000, name: 'Fondo Klar').budget }

    it 'un traspaso del fondo a la tarjeta la abona como pago' do
      make_transaction(user:, budget:, category: category_for('Internet'), amount: 3_326.62,
                       type_code: 'expense', transaction_date: Date.current)
      expect(card.reload.current_debt).to eq(3_326.62)

      Transaction.create!(user:, budget: fund, related_budget: budget, amount: 3_326.62,
                          description: 'Pago Klar', category: category_for('Internet'),
                          transaction_type: transaction_type_for('transfer'),
                          color: color_catalog, icon: icon_catalog,
                          currency: Currency.default || create(:currency),
                          transaction_date: Date.current)

      expect(card.reload.current_debt).to eq(0)
      expect(fund.reload.current_amount).to eq(8_000 - 3_326.62)
    end
  end
end
