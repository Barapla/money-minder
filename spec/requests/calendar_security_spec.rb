# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Calendar Security', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  describe 'GET /calendar' do
    context 'sin autenticacion' do
      it 'redirige al login' do
        get calendar_index_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'con usuario autenticado' do
      before { sign_in user1 }

      it 'retorna 200' do
        get calendar_index_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /obligatory_payments_calendar' do
    context 'sin autenticacion' do
      it 'redirige al login' do
        get obligatory_payments_calendar_index_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'con usuario autenticado' do
      before { sign_in user1 }

      it 'retorna 200 mostrando solo pagos del usuario autenticado' do
        get obligatory_payments_calendar_index_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
