# frozen_string_literal: true

require 'rails_helper'

# El flujo completo de recuperacion: pedir el enlace, recibir el correo y crear
# la contraseña nueva. Las dos pantallas viven fuera de la sesion, asi que usan
# el layout de auth y no el de la app.
RSpec.describe 'Recuperación de contraseña', type: :request do
  let(:password) { 'Secreta123!' }
  let!(:user) { create(:user, email: 'bryan@ejemplo.com', password:, password_confirmation: password) }

  describe 'GET /users/password/new' do
    it 'pide el correo, en español y con el panel de marca' do
      get new_user_password_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('¿Olvidaste tu contraseña?')
      expect(response.body).to include('Enviarme el enlace')
      expect(response.body).to include('Tus cuentas, tarjetas y Sofipos en una sola cuenta clara.')
    end

    # Sin `layout 'auth_application'` estas pantallas salian con el navbar y la
    # burbuja del chatbot, estando sin sesion.
    it 'no arrastra el navbar ni la burbuja del chatbot' do
      get new_user_password_path

      expect(response.body).not_to include('data-controller="chatbot-bubble"')
      expect(response.body).not_to include('navbar-dropdown-item')
    end
  end

  describe 'POST /users/password' do
    it 'manda el correo de recuperación en español' do
      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      mail = ActionMailer::Base.deliveries.last
      body = mail.body.encoded
      expect(body).to include('Crear una contrase') # asunto del boton, sin depender del encoding
      expect(body).not_to include('Change my password')
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET /users/password/edit' do
    it 'pide la contraseña nueva y su confirmación, con el toggle de cada una' do
      token = user.send_reset_password_instructions

      get edit_user_password_path(reset_password_token: token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Crea tu nueva contraseña')
      expect(response.body.scan('data-controller="password-visibility"').size).to eq(2)
      expect(response.body).to include('Mínimo 6 caracteres.')
    end
  end

  describe 'PUT /users/password' do
    it 'cambia la contraseña y deja entrar con la nueva' do
      token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: { reset_password_token: token, password: 'NuevaClave456!',
                password_confirmation: 'NuevaClave456!' }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.valid_password?('NuevaClave456!')).to be(true)
    end

    it 'muestra el error cuando la confirmación no coincide' do
      token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: { reset_password_token: token, password: 'NuevaClave456!',
                password_confirmation: 'otra-cosa' }
      }

      expect(response.body).to include('role="alert"')
      expect(user.reload.valid_password?('NuevaClave456!')).to be(false)
    end
  end
end
