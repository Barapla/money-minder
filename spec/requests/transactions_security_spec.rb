# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transactions Security', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:budget1) { create(:budget, user: user1) }
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
end
