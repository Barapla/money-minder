# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 cuenta (registro, recuperacion, perfil)', type: :request do
  let(:user) { create(:user, first_name: 'Ana', last_name: 'Rodríguez') }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt_token[:token]}" } }

  describe 'POST /api/v1/auth/register' do
    let(:params) do
      { name: 'Luis Pérez', email: 'luis@example.com', password: 'secret123', password_confirmation: 'secret123' }
    end

    before do
      # User#create_personal_budget necesita los catalogos de seeds.
      allow_any_instance_of(User).to receive(:create_personal_budget)
      create(:role, name: 'user') unless Role.exists?(name: 'user')
    end

    it 'crea el usuario y retorna un token' do
      expect { post api_v1_auth_register_path, params: }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['record']['token']).to be_a(String)
      expect(User.last).to have_attributes(first_name: 'Luis', last_name: 'Pérez')
    end

    it 'retorna 422 si el correo ya existe' do
      create(:user, email: 'luis@example.com')

      post api_v1_auth_register_path, params: params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']['details']).to have_key('email')
    end

    it 'retorna 422 si las contraseñas no coinciden' do
      post api_v1_auth_register_path, params: params.merge(password_confirmation: 'otra')

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/auth/password' do
    it 'envia instrucciones al correo existente' do
      expect { post api_v1_auth_password_path, params: { email: user.email } }
        .to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it 'responde 200 aunque el correo no exista (no revela cuentas)' do
      expect { post api_v1_auth_password_path, params: { email: 'nadie@example.com' } }
        .not_to(change { ActionMailer::Base.deliveries.size })

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /api/v1/auth/me' do
    it 'actualiza nombre y moneda' do
      currency = create(:currency)

      patch api_v1_auth_me_path, params: { name: 'Ana María López', currency_id: currency.id }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['record']).to include('name' => 'Ana María López', 'currency' => currency.code)
    end

    it 'retorna 401 sin token' do
      patch api_v1_auth_me_path, params: { name: 'X' }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/auth/password' do
    it 'cambia la contraseña con la contraseña actual correcta' do
      patch api_v1_auth_password_path,
            params: { current_password: 'password123', password: 'nueva1234', password_confirmation: 'nueva1234' },
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?('nueva1234')).to be(true)
    end

    it 'retorna 422 con la contraseña actual incorrecta' do
      patch api_v1_auth_password_path,
            params: { current_password: 'mala', password: 'nueva1234', password_confirmation: 'nueva1234' },
            headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?('password123')).to be(true)
    end
  end
end
