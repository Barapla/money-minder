# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/auth', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  describe 'POST /api/v1/auth/login' do
    context 'con credenciales validas' do
      it 'retorna HTTP 200 con token y expires_at en ISO8601' do
        post api_v1_auth_login_path, params: { email: user.email, password: 'password123' }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['record']['token']).to be_a(String)
        expect { Time.iso8601(json['record']['expires_at']) }.not_to raise_error
      end
    end

    context 'con password incorrecto' do
      it 'retorna HTTP 401 con mensaje de error' do
        post api_v1_auth_login_path, params: { email: user.email, password: 'incorrecta' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Credenciales inválidas'])
      end
    end

    context 'con usuario inexistente' do
      it 'retorna HTTP 401 con mensaje de error' do
        post api_v1_auth_login_path, params: { email: 'no-existe@example.com', password: 'password123' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Credenciales inválidas'])
      end
    end

    context 'sin parametros' do
      it 'retorna HTTP 401 con mensaje de error' do
        post api_v1_auth_login_path

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Credenciales inválidas'])
      end
    end
  end

  describe 'GET /api/v1/auth/me' do
    context 'con token valido' do
      it 'retorna HTTP 200 con datos basicos del usuario' do
        token = user.generate_jwt_token[:token]

        get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body['record']
        expect(json).to eq(
          'id' => user.id,
          'email' => user.email,
          'name' => "#{user.first_name} #{user.last_name}".strip
        )
      end
    end

    context 'con token expirado' do
      it 'retorna HTTP 401 con mensaje de error' do
        token = travel_to(31.days.ago) { user.generate_jwt_token[:token] }

        get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Token inválido o expirado'])
      end
    end

    context 'con token invalido' do
      it 'retorna HTTP 401 con mensaje de error' do
        get api_v1_auth_me_path, headers: { 'Authorization' => 'Bearer token-invalido' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Token inválido o expirado'])
      end
    end

    context 'sin token' do
      it 'retorna HTTP 401 con mensaje de error' do
        get api_v1_auth_me_path

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Token inválido o expirado'])
      end
    end

    context 'con token de un usuario que ya no existe' do
      it 'retorna HTTP 401 con mensaje de error' do
        token = user.generate_jwt_token[:token]
        user.destroy

        get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['errors']).to eq(['Token inválido o expirado'])
      end
    end
  end
end
