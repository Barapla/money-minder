# frozen_string_literal: true

require 'rails_helper'

# La pantalla de registro comparte el layout de auth con el login: mismo panel de
# marca a la izquierda y el mismo campo de contraseña con boton Mostrar/Ocultar.
RSpec.describe 'Pantalla de registro', type: :request do
  # User#create_personal_budget (after_create) crea el efectivo del usuario, y ese
  # Budget exige budget_type, icon y color del catalogo. En dev vienen del seed;
  # aqui hay que ponerlos o el alta revienta al guardar.
  before do
    Role.find_or_create_by!(name: 'user')
    { 'budget_types' => 'Efectivo', 'budget_icons' => '💵', 'colors' => 'purple-500' }.each do |group, value|
      code = group == 'colors' ? 'purple' : 'cash'
      group_catalog = GroupCatalog.find_or_create_by!(code: group) { |g| g.name = group }
      Catalog.find_or_create_by!(code:, group_catalog:) { |c| c.value = value }
    end
  end

  describe 'GET /users/sign_up' do
    it 'muestra el formulario con el panel de marca' do
      get new_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Regístrate para continuar en')
      expect(response.body).to include('Tus cuentas, tarjetas y Sofipos en una sola cuenta clara.')
    end

    it 'pide nombre, correo, contraseña y su confirmación' do
      get new_user_registration_path

      expect(response.body).to include('user[name]', 'user[email]')
      expect(response.body).to include('user[password]', 'user[password_confirmation]')
      expect(response.body).to include('Mínimo 6 caracteres.')
    end

    it 'usa el mismo campo de contraseña del login, uno por cada campo' do
      get new_user_registration_path

      expect(response.body.scan('data-controller="password-visibility"').size).to eq(2)
      expect(response.body).to include('data-hide="Ocultar"')
    end

    it 'enlaza de vuelta al inicio de sesión' do
      get new_user_registration_path

      expect(response.body).to include(new_user_session_path)
      expect(response.body).to include('¿Ya tienes cuenta?')
    end
  end

  describe 'POST /users' do
    let(:valid_params) do
      { user: { name: 'Bryan Araujo', email: 'bryan@ejemplo.com',
                password: 'Secreta123!', password_confirmation: 'Secreta123!' } }
    end

    it 'crea la cuenta y parte el nombre en nombre y apellido' do
      expect { post user_registration_path, params: valid_params }.to change(User, :count).by(1)

      user = User.find_by(email: 'bryan@ejemplo.com')
      expect(user.first_name).to eq('Bryan')
      expect(user.last_name).to eq('Araujo')
    end

    # El campo de confirmacion no existia en la vista anterior: una contraseña
    # mal tecleada creaba la cuenta igual y dejaba al usuario fuera.
    it 'rechaza la cuenta cuando la confirmación no coincide' do
      params = valid_params.deep_merge(user: { password_confirmation: 'otra-cosa' })

      expect { post user_registration_path, params: }.not_to change(User, :count)
      expect(response.body).to include('role="alert"')
    end

    it 'muestra los errores de validación en el banner oscuro, no en rojo sólido' do
      post user_registration_path, params: { user: { name: '', email: 'no-es-correo', password: '123' } }

      expect(response.body).to include('bg-red-500/10')
      expect(response.body).not_to include('alert alert-error mb-6 bg-red-500 text-white')
    end
  end
end
