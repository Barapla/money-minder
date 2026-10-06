# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/budgets', type: :request do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:budget_type) { create(:catalog, code: 'cash') }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }

  let(:valid_params) do
    {
      budget: {
        name: 'Efectivo manual',
        budget_type_id: budget_type.id,
        color_id: color.id,
        icon_id: icon.id,
        current_amount: 0
      }
    }
  end

  let(:catalog_product_params) do
    {
      budget: {
        name: 'sera reemplazado',
        budget_type_id: budget_type.id,
        color_id: color.id,
        icon_id: icon.id,
        current_amount: 0,
        financial_product_id: 'nu_credit_card'
      }
    }
  end

  before { sign_in user }

  describe 'POST /budgets sin producto del catalogo' do
    it 'crea el budget respetando el nombre manual' do
      expect do
        post budgets_path, params: valid_params
      end.to change(Budget, :count).by(1)

      expect(Budget.last.name).to eq('Efectivo manual')
      expect(Budget.last.financial_product_id).to be_nil
    end
  end

  describe 'POST /budgets con producto del catalogo (flujo completo FEAT-022)' do
    it 'crea el budget autogenerando el nombre a partir del producto' do
      expect do
        post budgets_path, params: catalog_product_params
      end.to change(Budget, :count).by(1)

      budget = Budget.last
      expect(budget.financial_product_id).to eq('nu_credit_card')
      expect(budget.name).to eq('Cuenta Nu Credito de Bryan')
    end
  end

  describe 'POST /budgets con financial_product_id invalido' do
    it 'no crea el budget y renderiza new' do
      params = catalog_product_params
      params[:budget][:financial_product_id] = 'no_existe'

      expect do
        post budgets_path, params: params
      end.not_to change(Budget, :count)

      expect(response).to have_http_status(:ok)
    end
  end
end
