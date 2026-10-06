# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports Security', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  describe 'GET /reports' do
    context 'sin autenticacion' do
      it 'redirige al login' do
        get reports_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'con usuario autenticado' do
      before { sign_in user1 }

      it 'retorna 200 mostrando solo datos del usuario autenticado' do
        allow(ReportFilter).to receive(:new).and_call_original
        get reports_path
        expect(response).to have_http_status(:ok)
        expect(ReportFilter).to have_received(:new).with(hash_including(user: user1))
      end
    end
  end

  describe 'POST /reports/flow_chart' do
    context 'sin autenticacion' do
      it 'retorna unauthorized para JSON' do
        post flow_chart_reports_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'con usuario autenticado' do
      before { sign_in user1 }

      it 'retorna datos de flujo solo del usuario autenticado' do
        post flow_chart_reports_path,
             params: { report: { filters: { start_date: 1.month.ago.to_date,
                                            end_date: Date.today, period: 'monthly' } } },
             as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
