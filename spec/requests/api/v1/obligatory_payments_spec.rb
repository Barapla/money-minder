# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/obligatory_payments', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt_token[:token]}" } }

  before { travel_to Date.new(2026, 9, 16) }

  describe 'GET' do
    it 'lista los recordatorios del usuario ordenados por proxima fecha' do
      later = make_obligatory_payment(user:, amount: 100, due_date: Date.new(2026, 9, 30))
      sooner = make_obligatory_payment(user:, amount: 200, due_date: Date.new(2026, 9, 20))
      make_obligatory_payment(user: create(:user), amount: 999)

      get api_v1_obligatory_payments_path, headers: auth_headers

      records = response.parsed_body['records']
      expect(records.map { |r| r['id'] }).to eq([sooner.id, later.id])
      expect(records.first).to include('next_due_date' => '2026-09-20', 'recurrence' => nil, 'amount' => 200.0)
    end

    it 'incluye la recurrencia y la proxima fecha de los recurrentes' do
      make_obligatory_payment(user:, amount: 100, recurring: true)

      get api_v1_obligatory_payments_path, headers: auth_headers

      record = response.parsed_body['records'].first
      expect(record['recurrence']).to include('frequency' => 'monthly', 'frequency_value' => 1)
      expect(record['next_due_date']).to eq('2026-09-16')
    end

    it 'filtra por reminder_type' do
      make_obligatory_payment(user:, amount: 100)
      income = make_obligatory_payment(user:, amount: 100, reminder_type: 'income')

      get api_v1_obligatory_payments_path, params: { reminder_type: 'income' }, headers: auth_headers

      expect(response.parsed_body['records'].map { |r| r['id'] }).to eq([income.id])
    end
  end

  describe 'POST' do
    let(:base) do
      { name: 'Renta', amount: 6700, reminder_type: 'payment', category_id: category_for('Vivienda').id,
        icon_id: icon_catalog.id, color_id: color_catalog.id }
    end

    it 'crea un recordatorio unico' do
      post api_v1_obligatory_payments_path,
           params: { obligatory_payment: base.merge(due_date: '2026-10-01') }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['record']).to include('name' => 'Renta', 'due_date' => '2026-10-01')
    end

    it 'crea un recordatorio recurrente' do
      recurrence_group = GroupCatalog.find_or_create_by!(code: 'recurrenceable_types') { |g| g.name = 'x' }
      Catalog.find_or_create_by!(code: 'obligatory_payment', group_catalog: recurrence_group) { |c| c.value = 'x' }

      post api_v1_obligatory_payments_path,
           params: { obligatory_payment: base.merge(
             recurrence: { frequency_type_id: frequency_type_for('monthly').id, frequency_value: 1,
                           start_date: '2026-09-01' }
           ) },
           headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['record']).to include('next_due_date' => '2026-10-01', 'due_date' => nil)
    end

    it 'retorna 422 si un recordatorio unico no tiene fecha' do
      post api_v1_obligatory_payments_path, params: { obligatory_payment: base }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']['details']).to have_key('due_date')
    end
  end
end
