# frozen_string_literal: true

require 'rails_helper'

# La pantalla de login: panel de marca a la izquierda, formulario a la derecha.
RSpec.describe 'Pantalla de inicio de sesión', type: :request do
  # La factory fija password_confirmation: cambiar solo `password` la invalida.
  let(:password) { 'Secreta123!' }
  let!(:user) { create(:user, email: 'bryan@ejemplo.com', password:, password_confirmation: password) }

  describe 'GET /users/sign_in' do
    it 'muestra el formulario con el panel de marca' do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Inicia sesión para continuar en')
      expect(response.body).to include('Tus cuentas, tarjetas y Sofipos en una sola cuenta clara.')
      expect(response.body).to include('Libre para gastar', 'Cortes y pagos al día')
    end

    it 'ofrece registrarse, recuperar la contraseña y mantener la sesión' do
      get new_user_session_path

      expect(response.body).to include(new_user_registration_path)
      expect(response.body).to include(new_user_password_path)
      expect(response.body).to include('Mantener mi sesión iniciada')
    end

    it 'monta el botón de mostrar/ocultar sobre el campo de contraseña' do
      get new_user_session_path

      expect(response.body).to include('data-controller="password-visibility"')
      expect(response.body).to include('password-visibility#toggle')
      expect(response.body).to include('data-hide="Ocultar"')
    end
  end

  # Antes de esto ningun layout renderizaba flash: al fallar el login volvia el
  # formulario sin una sola palabra de por que.
  describe 'POST /users/sign_in con credenciales malas' do
    it 'muestra el aviso de error en la propia pantalla' do
      post user_session_path, params: { user: { email: user.email, password: 'incorrecta' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('role="alert"')
      expect(response.body).to include(I18n.t('devise.failure.invalid', authentication_keys: 'Email'))
    end
  end

  describe 'POST /users/sign_in con credenciales buenas' do
    it 'entra' do
      post user_session_path, params: { user: { email: user.email, password: } }

      expect(response).to redirect_to(root_path)
    end
  end
end
