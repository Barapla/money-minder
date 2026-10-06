# frozen_string_literal: true

require 'rails_helper'

# /users/edit, enlazada desde el navbar como "Editar perfil". Corre con el layout
# de la app (hay sesion), no con el de auth.
RSpec.describe 'Pantalla de cuenta', type: :request do
  let(:password) { 'Secreta123!' }
  let(:user) { create(:user, email: 'bryan@ejemplo.com', password:, password_confirmation: password) }

  before { sign_in user }

  describe 'GET /users/edit' do
    it 'muestra nombre, correo y el bloque de cambiar contraseña, en español' do
      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Editar Perfil')
      expect(response.body).to include('Entras con bryan@ejemplo.com')
      expect(response.body).to include('Cambiar la contraseña')
      expect(response.body).not_to include('Edit User')
      expect(response.body).not_to include("leave blank if you don't want to change it")
    end

    it 'pide la contraseña actual y usa el campo compartido en los tres' do
      get edit_user_registration_path

      expect(response.body).to include('user[current_password]')
      expect(response.body.scan('data-controller="password-visibility"').size).to eq(3)
    end

    it 'ofrece eliminar la cuenta detrás de una confirmación' do
      get edit_user_registration_path

      expect(response.body).to include('Eliminar mi cuenta')
      expect(response.body).to include('data-turbo-confirm="¿Estás seguro?"')
    end
  end

  describe 'PUT /users' do
    it 'guarda el nombre con la contraseña actual' do
      put user_registration_path, params: {
        user: { name: 'Bryan Araujo', email: user.email, current_password: password }
      }

      expect(user.reload.first_name).to eq('Bryan')
      expect(user.last_name).to eq('Araujo')
    end

    it 'rechaza el cambio si la contraseña actual está mal' do
      put user_registration_path, params: {
        user: { email: 'otro@ejemplo.com', current_password: 'no-es-la-mia' }
      }

      expect(user.reload.email).to eq('bryan@ejemplo.com')
      expect(response.body).to include('role="alert"')
    end
  end
end
