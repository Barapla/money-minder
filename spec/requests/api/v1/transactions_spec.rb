# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/transactions', type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_jwt_token[:token] }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 0, personal: true) }
  let(:category) { category_for('Comida') }

  def sql_query_count(&block)
    count = 0
    callback = lambda { |*, payload|
      count += 1 unless payload[:name].in?(%w[SCHEMA CACHE])
    }

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
    count
  end

  describe 'GET /api/v1/transactions' do
    context 'CA9: usuario autenticado' do
      it 'retorna transacciones del usuario ordenadas por date DESC con los campos esperados' do
        older = make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense',
                                 transaction_date: 2.days.ago.to_date)
        newer = make_transaction(user:, budget:, category:, amount: 200, type_code: 'expense',
                                 transaction_date: Date.current)

        get api_v1_transactions_path, headers: auth_headers

        expect(response).to have_http_status(:ok)
        records = response.parsed_body['records']
        expect(records.map { |r| r['id'] }).to eq([newer.id, older.id])
        expect(records.first.keys).to contain_exactly(
          'id', 'date', 'amount', 'currency', 'description', 'category_name', 'transaction_type',
          'icon', 'color', 'created_at', 'updated_at'
        )
        expect(records.first['category_name']).to eq('Comida')
        expect(records.first['transaction_type']).to eq('expense')
      end
    end

    context 'CA10: paginacion' do
      it 'retorna la pagina solicitada con meta de paginacion' do
        25.times { |i| make_transaction(user:, budget:, category:, amount: 100 + i, type_code: 'expense') }

        get api_v1_transactions_path, params: { page: 2, per_page: 20 }, headers: auth_headers

        expect(response.parsed_body['records'].size).to eq(5)
        expect(response.parsed_body['meta']).to eq(
          'current_page' => 2, 'total_pages' => 2, 'total_count' => 25, 'net_total' => -2800.0
        )
      end

      it 'usa 20 por defecto cuando no se especifica per_page' do
        21.times { make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense') }

        get api_v1_transactions_path, headers: auth_headers

        expect(response.parsed_body['records'].size).to eq(20)
        expect(response.parsed_body['meta']['total_pages']).to eq(2)
      end
    end

    context 'aislamiento por usuario' do
      it 'no incluye transacciones de otro usuario' do
        other_user = create(:user)
        other_budget = make_budget(user: other_user, type_code: 'cash', amount: 0, personal: true)
        make_transaction(user: other_user, budget: other_budget, category:, amount: 999, type_code: 'expense')
        own = make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense')

        get api_v1_transactions_path, headers: auth_headers

        expect(response.parsed_body['records'].map { |r| r['id'] }).to eq([own.id])
      end
    end

    context 'CA14: N+1 en la consulta de categorias' do
      it 'no incrementa el numero de queries al agregar mas transacciones' do
        3.times { make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense') }
        baseline = sql_query_count { get api_v1_transactions_path, headers: auth_headers }

        10.times do
          make_transaction(user:, budget:, category: category_for('Transporte'), amount: 50,
                           type_code: 'expense')
        end
        with_more_records = sql_query_count { get api_v1_transactions_path, headers: auth_headers }

        expect(with_more_records).to eq(baseline)
      end
    end

    context 'CA13: sin token' do
      it 'retorna HTTP 401' do
        get api_v1_transactions_path

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/transactions/:id' do
    context 'CA11: la transaccion pertenece al usuario' do
      it 'retorna el detalle completo' do
        transaction = make_transaction(user:, budget:, category:, amount: 250, type_code: 'expense')

        get api_v1_transaction_path(transaction), headers: auth_headers

        expect(response).to have_http_status(:ok)
        record = response.parsed_body['record']
        expect(record['id']).to eq(transaction.id)
        expect(record['amount']).to eq(250.0)
        expect(record['category_name']).to eq('Comida')
      end
    end

    context 'CA12: la transaccion no pertenece al usuario' do
      it 'retorna HTTP 404' do
        other_user = create(:user)
        other_budget = make_budget(user: other_user, type_code: 'cash', amount: 0, personal: true)
        foreign_transaction = make_transaction(user: other_user, budget: other_budget, category:, amount: 100,
                                               type_code: 'expense')

        get api_v1_transaction_path(foreign_transaction), headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'CA13: sin token' do
      it 'retorna HTTP 401' do
        transaction = make_transaction(user:, budget:, category:, amount: 100, type_code: 'expense')

        get api_v1_transaction_path(transaction)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/transactions con filtros' do
    let!(:super_tx) do
      make_transaction(user:, budget:, category:, amount: 300, type_code: 'expense',
                       transaction_date: Date.new(2026, 9, 10)).tap { |t| t.update!(description: 'Supermercado') }
    end
    let!(:salary) do
      make_transaction(user:, budget:, category: category_for('Sueldo'), amount: 1000, type_code: 'income',
                       transaction_date: Date.new(2026, 9, 1)).tap { |t| t.update!(description: 'Nómina') }
    end
    let!(:old_tx) do
      make_transaction(user:, budget:, category:, amount: 50, type_code: 'expense',
                       transaction_date: Date.new(2026, 8, 20)).tap { |t| t.update!(description: 'Tacos') }
    end

    def ids_for(params)
      get api_v1_transactions_path, params:, headers: auth_headers
      response.parsed_body['records'].map { |r| r['id'] }
    end

    it 'busca por descripcion o categoria sin distinguir mayusculas' do
      expect(ids_for(q: 'SUPER')).to eq([super_tx.id])
      expect(ids_for(q: 'comida')).to eq([super_tx.id, old_tx.id])
    end

    it 'filtra por tipo, categoria y rango de fechas' do
      expect(ids_for(transaction_type: 'income')).to eq([salary.id])
      expect(ids_for(category: 'Comida')).to eq([super_tx.id, old_tx.id])
      expect(ids_for(start_date: '2026-09-01', end_date: '2026-09-30')).to eq([super_tx.id, salary.id])
    end

    it 'calcula total_count y net_total sobre el resultado filtrado' do
      get api_v1_transactions_path, params: { start_date: '2026-09-01' }, headers: auth_headers

      expect(response.parsed_body['meta']).to include('total_count' => 2, 'net_total' => 700.0)
    end

    it 'retorna 400 con una fecha invalida' do
      get api_v1_transactions_path, params: { start_date: '10/09/2026' }, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']['code']).to eq('invalid_date')
    end
  end

  describe 'POST /api/v1/transactions' do
    let!(:mxn) { Currency.default || create(:currency, code: 'MXN') }
    let(:valid_params) do
      { transaction: { transaction_type_id: transaction_type_for('expense').id, amount: 150.5,
                       description: 'Cine', category_id: category.id, transaction_date: '2026-09-12',
                       budget_id: budget.id, icon_id: icon_catalog.id, color_id: color_catalog.id } }
    end

    it 'crea la transaccion para el usuario autenticado' do
      expect { post api_v1_transactions_path, params: valid_params, headers: auth_headers }
        .to change(user.transactions, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['record']).to include(
        'description' => 'Cine', 'amount' => 150.5, 'date' => '2026-09-12', 'transaction_type' => 'expense',
        'currency' => 'MXN'
      )
    end

    it 'usa la moneda predeterminada del usuario si la tiene' do
      usd = create(:currency, code: 'USD')
      user.update!(currency: usd)

      post api_v1_transactions_path, params: valid_params, headers: auth_headers

      expect(response.parsed_body['record']['currency']).to eq('USD')
    end

    it 'rechaza un presupuesto de otro usuario con 422' do
      other_budget = make_budget(user: create(:user), type_code: 'cash', amount: 0, personal: true)
      params = valid_params.deep_merge(transaction: { budget_id: other_budget.id })

      expect { post api_v1_transactions_path, params:, headers: auth_headers }
        .not_to change(Transaction, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']['code']).to eq('validation_error')
    end

    it 'retorna 422 cuando faltan campos requeridos' do
      post api_v1_transactions_path, params: { transaction: { amount: 10 } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']['details']).to be_present
    end

    it 'retorna 401 sin token' do
      post api_v1_transactions_path, params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
