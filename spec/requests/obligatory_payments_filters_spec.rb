# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Obligatory payments filters', type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it 'renders el index con los selectores de filtro sin errores' do
    get obligatory_payments_path

    expect(response).to have_http_status(:ok)
  end

  it 'renders el index con filtros aplicados sin errores' do
    get obligatory_payments_path, params: { reminder_type: 'payment', recurrence_filter: 'recurring' }

    expect(response).to have_http_status(:ok)
  end
end
