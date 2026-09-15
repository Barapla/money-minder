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
          'created_at', 'updated_at'
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
          'current_page' => 2, 'total_pages' => 2, 'total_count' => 25
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
end
