# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/saving_goals', type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt_token[:token]}" } }

  describe 'GET' do
    it 'asigna el saldo disponible por prioridad y lista primero las activas' do
      make_budget(user:, type_code: 'cash', amount: 30_000, personal: true)
      first = create(:saving_goal, user:, target_amount: 20_000)
      second = create(:saving_goal, user:, target_amount: 20_000)
      paused = create(:saving_goal, user:, target_amount: 5_000, status: :paused)
      create(:saving_goal, user: create(:user))

      get api_v1_saving_goals_path, headers: auth_headers

      records = response.parsed_body['records']
      expect(records.map { |r| r['id'] }).to eq([first.id, second.id, paused.id])
      expect(records[0]).to include('allocated_amount' => 20_000.0, 'progress_percentage' => 100.0)
      expect(records[1]).to include('allocated_amount' => 10_000.0, 'progress_percentage' => 50.0)
      expect(records[2]).to include('allocated_amount' => 0.0, 'status' => 'paused')
    end
  end

  describe 'POST' do
    it 'crea la meta con la siguiente prioridad' do
      post api_v1_saving_goals_path,
           params: { saving_goal: { name: 'Viaje', target_amount: 60_000, deadline: 1.year.from_now.to_date } },
           headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['record']).to include('name' => 'Viaje', 'priority_order' => 1, 'status' => 'active')
    end

    it 'retorna 422 con monto invalido' do
      post api_v1_saving_goals_path, params: { saving_goal: { name: 'X', target_amount: 0 } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']['details']).to have_key('target_amount')
    end
  end
end
