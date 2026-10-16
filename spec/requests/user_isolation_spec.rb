# frozen_string_literal: true

require 'rails_helper'

# Ningun usuario debe ver ni tocar datos de otro: ni por URL, ni por un id
# mandado a mano en un formulario, ni en las opciones de un select.
RSpec.describe 'Aislamiento entre usuarios', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:own_budget) { create(:budget, user:, name: 'Cuenta propia') }
  let!(:foreign_budget) { create(:budget, user: other_user, name: 'Cuenta ajena') }

  before { sign_in user }

  describe 'selects de presupuestos' do
    it 'el filtro del calendario solo lista presupuestos propios' do
      get advanced_search_calendar_index_path

      expect(response.body).to include('Cuenta propia')
      expect(response.body).not_to include('Cuenta ajena')
    end
  end

  describe 'transacciones recurrentes' do
    it 'no abre el modal sobre la transaccion de otro usuario' do
      foreign_transaction = create(:transaction, user: other_user, budget: foreign_budget)

      get new_modal_recurring_transactions_path(transaction_id: foreign_transaction.id)

      expect(response).to have_http_status(:not_found)
    end

    it 'no crea una recurrencia a partir de la transaccion de otro usuario' do
      foreign_transaction = create(:transaction, user: other_user, budget: foreign_budget)

      expect do
        post recurring_transactions_path, params: {
          recurring_transaction: { frequency: 'monthly', start_date: Date.current },
          transaction: { id: foreign_transaction.id, budget_id: foreign_budget.id }
        }
      end.not_to change(RecurringTransaction, :count)
      expect(foreign_transaction.reload.recurring_transaction_id).to be_nil
    end

    it 'rechaza una recurrencia con el presupuesto de otro usuario' do
      recurrence = RecurringTransaction.new(user:, frequency: 'monthly', start_date: Date.current,
                                            transaction_options: { 'budget_id' => foreign_budget.id })

      expect(recurrence).not_to be_valid
    end
  end

  describe 'deudas' do
    it 'no liga una deuda al presupuesto de otro usuario' do
      debt = build(:debt, user:, budget: foreign_budget)

      expect(debt).not_to be_valid
      expect(debt.errors[:budget_id]).to include('debe pertenecer al mismo usuario')
    end

    it 'no abona la deuda de un usuario con la transaccion de otro' do
      allocation = DebtAllocation.new(debt: create(:debt, user:), amount: 10,
                                      transaction_record: create(:transaction, user: other_user,
                                                                               budget: foreign_budget))

      expect(allocation).not_to be_valid
    end
  end

  describe 'panel de Sidekiq' do
    it 'no es accesible para un usuario normal' do
      expect { get '/sidekiq' }.to raise_error(ActionController::RoutingError)
    end

    it 'es accesible para un admin' do
      sign_in create(:user, :admin)

      get '/sidekiq'

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'API con cuenta bloqueada' do
    # Otro usuario que el de la sesion web: si se bloquea ese, Warden redirige al
    # login de la web antes de llegar a la API.
    let(:api_user) { create(:user) }

    it 'rechaza el login y los tokens ya emitidos' do
      token = api_user.generate_jwt_token[:token]
      api_user.lock_access!(send_instructions: false)

      post api_v1_auth_login_path, params: { email: api_user.email, password: 'password123' }
      expect(response).to have_http_status(:unauthorized)

      get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rechaza el login de una cuenta sin confirmar pasado el plazo de gracia' do
      api_user.update_columns(confirmed_at: nil, confirmation_sent_at: 3.days.ago, created_at: 3.days.ago)

      post api_v1_auth_login_path, params: { email: api_user.email, password: 'password123' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'bloquea la cuenta tras demasiados intentos fallidos por la API' do
      Devise.maximum_attempts.times do
        post api_v1_auth_login_path, params: { email: api_user.email, password: 'incorrecta' }
      end

      expect(api_user.reload).to be_access_locked
    end
  end
end
