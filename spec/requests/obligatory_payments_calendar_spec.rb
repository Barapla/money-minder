# frozen_string_literal: true

require 'rails_helper'

# FEAT-029: el TOTAL DEL MES debe netear cobros (positivo) y pagos (negativo),
# no sumarlos como si todos fueran el mismo signo.
RSpec.describe 'GET /obligatory-payments-calendar', type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  before { sign_in user }

  it 'calcula el balance neto del mes restando pagos y sumando cobros' do
    create(:obligatory_payment, user:, category:, reminder_type: 'payment', amount: 100, due_date: Date.current)
    create(:obligatory_payment, user:, category:, reminder_type: 'income', amount: 300, due_date: Date.current)

    get obligatory_payments_calendar_index_path

    expect(response.body).to include('$200.00')
  end
end
