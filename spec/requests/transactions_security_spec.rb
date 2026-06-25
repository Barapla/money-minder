# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transactions Security', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:budget1) { create(:budget, user: user1) }
  let(:budget2) { create(:budget, user: user2) }
  let(:transaction1) { create(:transaction, user: user1, budget: budget1) }

  describe 'GET /transactions' do
    context 'cuando user2 esta autenticado' do
      before do
        transaction1
        sign_in user2
      end

      it 'solo retorna transacciones del usuario autenticado' do
        get transactions_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'sin autenticacion' do
      it 'redirige al login' do
        get transactions_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /transactions/:id' do
    context 'cuando user2 intenta acceder a transaccion de user1' do
      before { sign_in user2 }

      it 'retorna 404' do
        get transaction_path(transaction1)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'cuando el dueno accede a su propia transaccion' do
      let(:expense_type) { create(:catalog, code: 'expense') }
      let(:owner_transaction) { create(:transaction, user: user1, budget: budget1, transaction_type: expense_type) }

      before { sign_in user1 }

      it 'retorna 200' do
        get transaction_path(owner_transaction)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /transactions/:id/edit' do
    context 'cuando user2 intenta editar transaccion de user1' do
      before { sign_in user2 }

      it 'retorna 404' do
        get edit_transaction_path(transaction1)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /transactions/:id' do
    context 'cuando user2 intenta actualizar transaccion de user1' do
      before { sign_in user2 }

      it 'retorna 404' do
        patch transaction_path(transaction1), params: { transaction: { amount: 999 } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /transactions/:id' do
    context 'cuando user2 intenta eliminar transaccion de user1' do
      before { sign_in user2 }

      it 'retorna 404 y no elimina la transaccion' do
        delete transaction_path(transaction1)
        expect(response).to have_http_status(:not_found)
        expect(Transaction.find_by(id: transaction1.id)).to be_present
      end
    end
  end

  describe 'GET /transactions/new' do
    context 'cuando el usuario esta autenticado' do
      before { sign_in user1 }

      it 'el selector de budgets solo incluye budgets propios' do
        budget1
        budget2
        get new_transaction_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(budget1.name)
        expect(response.body).not_to include(budget2.name)
      end
    end
  end

  describe 'POST /transactions con budget ajeno' do
    let(:expense_type) { create(:catalog, code: 'expense') }
    let(:category) { create(:category) }
    let(:color) { create(:catalog) }
    let(:icon) { create(:catalog) }

    context 'cuando user1 intenta crear una transaccion con budget de user2' do
      before { sign_in user1 }

      it 'retorna 422 y no crea la transaccion' do
        expect do
          post transactions_path, params: {
            transaction: {
              amount: 100,
              description: 'Transaccion con budget ajeno',
              transaction_date: Date.today,
              budget_id: budget2.id,
              transaction_type_id: expense_type.id,
              category_id: category.id,
              color_id: color.id,
              icon_id: icon.id
            }
          }
        end.not_to change(Transaction, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /transactions/:id con budget ajeno' do
    context 'cuando user1 intenta mover su transaccion al budget de user2' do
      before { sign_in user1 }

      it 'retorna 422 y no actualiza la transaccion' do
        patch transaction_path(transaction1), params: {
          transaction: { budget_id: budget2.id }
        }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(transaction1.reload.budget_id).to eq(budget1.id)
      end
    end
  end
end
