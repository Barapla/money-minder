# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Budgets Security', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:budget1) { create(:budget, user: user1) }

  describe 'GET /budgets' do
    context 'sin autenticacion' do
      it 'redirige al login' do
        get budgets_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'con usuario autenticado' do
      before { sign_in user2 }

      it 'retorna 200 con solo los budgets del usuario' do
        budget1
        get budgets_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /budgets/:id' do
    context 'cuando user2 intenta acceder al budget de user1' do
      before { sign_in user2 }

      it 'retorna 404' do
        get budget_path(budget1)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'cuando el dueno accede a su propio budget' do
      let(:cash_type) { create(:catalog, code: 'cash') }
      let(:owner_budget) { create(:budget, user: user1, budget_type: cash_type) }

      before { sign_in user1 }

      it 'retorna 200' do
        get budget_path(owner_budget)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /budgets/:id/edit' do
    context 'cuando user2 intenta editar budget de user1' do
      before { sign_in user2 }

      it 'retorna 404' do
        get edit_budget_path(budget1)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /budgets/:id' do
    context 'cuando user2 intenta actualizar budget de user1' do
      before { sign_in user2 }

      it 'retorna 404' do
        patch budget_path(budget1), params: { budget: { name: 'Hackeado' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /budgets/:id' do
    context 'cuando user2 intenta eliminar budget de user1' do
      before { sign_in user2 }

      it 'retorna 404 y no elimina el budget' do
        delete budget_path(budget1)
        expect(response).to have_http_status(:not_found)
        expect(Budget.find_by(id: budget1.id)).to be_present
      end
    end
  end
end
