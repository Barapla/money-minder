# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /api/v1/catalogs', type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt_token[:token]}" } }

  it 'retorna las opciones de formulario del usuario' do
    income_parent = category_for('Ingresos')
    salary = category_for('Sueldo', parent: income_parent)
    food = category_for('Comida', parent: category_for('Alimentación'))
    transaction_type_for('income')
    transaction_type_for('transfer')
    own_budget = make_budget(user:, type_code: 'cash', amount: 0, personal: true, name: 'Efectivo')
    make_budget(user: create(:user), type_code: 'cash', amount: 0, name: 'Ajeno')

    get api_v1_catalogs_path, headers: auth_headers

    expect(response).to have_http_status(:ok)
    record = response.parsed_body['record']
    expect(record['transaction_types'].map { |t| t['code'] }).to eq(['income'])
    expect(record['categories']['income']).to eq([{ 'id' => salary.id, 'name' => 'Sueldo' }])
    expect(record['categories']['expense']).to eq([{ 'id' => food.id, 'name' => 'Comida' }])
    expect(record['budgets']).to eq(
      [{ 'id' => own_budget.id, 'name' => 'Efectivo', 'budget_type' => 'cash', 'personal' => true }]
    )
    expect(record.keys).to include('transaction_icons', 'colors', 'frequency_types', 'currencies')
  end

  it 'retorna 401 sin token' do
    get api_v1_catalogs_path

    expect(response).to have_http_status(:unauthorized)
  end
end
