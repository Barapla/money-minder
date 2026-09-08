# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/financial_products', type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'GET /financial_products (FEAT-026)' do
    it 'retorna los productos del catalogo filtrados por tipo e institucion' do
      get financial_products_path(type: 'credit', institution: 'Nu')

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([{ 'id' => 'nu_credit_card', 'name' => 'Nu Credito' }])
    end

    it 'retorna vacio cuando no hay productos para esa institucion' do
      get financial_products_path(type: 'credit', institution: 'No Existe')

      expect(JSON.parse(response.body)).to eq([])
    end

    it 'retorna vacio cuando el tipo no esta en la whitelist' do
      get financial_products_path(type: 'admin', institution: 'Nu')

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe 'sin autenticacion' do
    before { sign_out user }

    it 'redirige al login' do
      get financial_products_path(type: 'credit', institution: 'Nu')

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
