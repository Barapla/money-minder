# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /api/v1/calendar', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.generate_jwt_token[:token]}" } }
  let(:budget) { make_budget(user:, type_code: 'cash', amount: 0, personal: true) }

  before { travel_to Date.new(2026, 9, 16) }

  it 'retorna las transacciones y las ocurrencias de recordatorios del mes pedido' do
    inside = make_transaction(user:, budget:, category: category_for('Comida'), amount: 100, type_code: 'expense',
                              transaction_date: Date.new(2026, 10, 3))
    make_transaction(user:, budget:, category: category_for('Comida'), amount: 100, type_code: 'expense',
                     transaction_date: Date.new(2026, 9, 3))
    weekly = make_obligatory_payment(user:, amount: 50, recurring: true, frequency_code: 'weekly')
    one_time = make_obligatory_payment(user:, amount: 80, due_date: Date.new(2026, 10, 20))

    get api_v1_calendar_path, params: { month: '2026-10' }, headers: auth_headers

    record = response.parsed_body['record']
    expect(record['month']).to eq('2026-10')
    expect(record['transactions'].map { |t| t['id'] }).to eq([inside.id])
    weekly_dates = record['reminders'].select { |r| r['id'] == weekly.id }.map { |r| r['date'] }
    expect(weekly_dates).to eq(%w[2026-10-07 2026-10-14 2026-10-21 2026-10-28])
    expect(record['reminders'].find { |r| r['id'] == one_time.id }['date']).to eq('2026-10-20')
  end

  it 'usa el mes actual por defecto' do
    get api_v1_calendar_path, headers: auth_headers

    expect(response.parsed_body['record']['month']).to eq('2026-09')
  end

  it 'retorna 400 con un mes invalido' do
    get api_v1_calendar_path, params: { month: '2026-13' }, headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body['error']['code']).to eq('invalid_month')
  end
end
