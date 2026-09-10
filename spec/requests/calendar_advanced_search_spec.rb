# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Calendar advanced search', type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it 'renders sin errores cuando una categoria no tiene icono asignado' do
    parent = create(:category)
    create(:category, parent_category: parent, icon: nil)

    get advanced_search_calendar_index_path

    expect(response).to have_http_status(:ok)
  end
end
