# frozen_string_literal: true

require 'rails_helper'

# FEAT-027: wizard de creacion paso a paso. Cubre navegacion entre pasos, persistencia
# del estado en session, el atajo para tipos sin productos en el catalogo (cash) y la
# opcion "Otro" para continuar sin producto asociado.
RSpec.describe 'Wizard de creacion de presupuestos (FEAT-027)', type: :request do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }

  def create_budget_type(code)
    create(:catalog, code:, group_catalog: budget_types_group)
  end

  before { sign_in user }

  describe 'GET /budgets/new (paso 1)' do
    it 'CA1: resetea el estado del wizard' do
      get new_budget_path

      expect(response).to have_http_status(:ok)
      expect(session[:budget_wizard]).to eq({})
    end
  end

  describe 'GET /budgets/wizard_step2 (paso 2)' do
    it 'CA2: guarda el tipo en session y lista solo instituciones con productos de ese tipo' do
      create_budget_type('credit_card')

      get wizard_step2_budgets_path(type: 'credit_card')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Nu')
      expect(session[:budget_wizard]).to eq('type' => 'credit_card')
    end

    it 'salta directo al paso 4 cuando el tipo no tiene productos en el catalogo (cash)' do
      create_budget_type('cash')

      get wizard_step2_budgets_path(type: 'cash')

      expect(response).to redirect_to(wizard_step4_budgets_path)
    end

    it 'redirige al paso 1 si el tipo no existe' do
      get wizard_step2_budgets_path(type: 'nonexistent')

      expect(response).to redirect_to(new_budget_path)
    end

    it 'redirige al paso 1 si el tipo no esta soportado por el wizard aunque exista en el catalogo' do
      create_budget_type('tipo_sin_registro')

      get wizard_step2_budgets_path(type: 'tipo_sin_registro')

      expect(response).to redirect_to(new_budget_path)
    end
  end

  describe 'GET /budgets/wizard_step3 (paso 3)' do
    it 'CA4: guarda la institucion en session y lista solo productos de esa institucion y tipo' do
      create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')

      get wizard_step3_budgets_path(institution: 'Nu')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Nu Credito')
      expect(response.body).not_to include('Mercado Pago')
      expect(session[:budget_wizard]).to eq('type' => 'credit_card', 'institution' => 'Nu')
    end

    it 'redirige al paso 1 si no hay tipo seleccionado en session' do
      get wizard_step3_budgets_path(institution: 'Nu')

      expect(response).to redirect_to(new_budget_path)
    end

    it 'redirige al paso 2 si la institucion no existe para ese tipo (evita session tampering)' do
      create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')

      get wizard_step3_budgets_path(institution: 'Institucion Inventada')

      expect(response).to redirect_to(wizard_step2_budgets_path)
      expect(session[:budget_wizard]['institution']).to be_nil
    end
  end

  describe 'GET /budgets/wizard_step4 (paso 4)' do
    it 'CA6: precarga el producto elegido en el paso 3' do
      create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')
      get wizard_step3_budgets_path(institution: 'Nu')

      get wizard_step4_budgets_path(product_id: 'nu_credit_card')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Nu Credito')
      expect(session[:budget_wizard]['product_id']).to eq('nu_credit_card')
    end

    it 'CA8: "Atras" hacia el paso 3 mantiene la institucion guardada en session' do
      create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')
      get wizard_step3_budgets_path(institution: 'Nu')
      get wizard_step4_budgets_path(product_id: 'nu_credit_card')

      get wizard_step3_budgets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Nu Credito')
    end

    it 'permite continuar sin producto del catalogo (opcion "Otro")' do
      create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')

      get wizard_step4_budgets_path(product_id: '')

      expect(response).to have_http_status(:ok)
      expect(session[:budget_wizard]['product_id']).to eq('')
    end
  end

  describe 'POST /budgets (creacion final del wizard)' do
    it 'CA10: crea el presupuesto con el producto financiero asociado y limpia el estado del wizard' do
      budget_type = create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')
      get wizard_step3_budgets_path(institution: 'Nu')
      get wizard_step4_budgets_path(product_id: 'nu_credit_card')

      params = {
        name: 'sera reemplazado',
        budget_type_id: budget_type.id,
        color_id: color.id,
        icon_id: icon.id,
        credit_card_attributes: {
          initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5,
          financial_product_id: 'nu_credit_card'
        }
      }

      expect do
        post budgets_path, params: { budget: params }
      end.to change(Budget, :count).by(1)

      budget = Budget.last
      expect(budget.credit_card.financial_product_id).to eq('nu_credit_card')
      expect(budget.name).to eq('Cuenta Nu Credito de Bryan')
      expect(session[:budget_wizard]).to be_nil
    end

    it 'agrega el apodo opcional entre parentesis al nombre autogenerado' do
      budget_type = create_budget_type('credit_card')
      get wizard_step2_budgets_path(type: 'credit_card')
      get wizard_step3_budgets_path(institution: 'Nu')
      get wizard_step4_budgets_path(product_id: 'nu_credit_card')

      params = {
        budget_type_id: budget_type.id,
        color_id: color.id,
        icon_id: icon.id,
        credit_card_attributes: {
          initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5,
          financial_product_id: 'nu_credit_card', nickname: 'Negocio'
        }
      }

      post budgets_path, params: { budget: params }

      expect(Budget.last.name).to eq('Cuenta Nu Credito de Bryan (Negocio)')
    end

    it 're-renderiza el paso 4 (no el paso 1) cuando la creacion falla' do
      budget_type = create_budget_type('cash')

      post budgets_path, params: { budget: { budget_type_id: budget_type.id, color_id: color.id } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('budgets.wizard.step_4.heading'))
    end

    it 'crea un ahorro a plazo fijo con producto del catalogo sin pedir nombre del presupuesto' do
      budget_type = create_budget_type('term_saving')
      get wizard_step2_budgets_path(type: 'term_saving')
      get wizard_step3_budgets_path(institution: 'Nu')
      get wizard_step4_budgets_path(product_id: 'nu_frozen_savings90')

      expect(response).to have_http_status(:ok)

      params = {
        budget_type_id: budget_type.id,
        color_id: color.id,
        icon_id: icon.id,
        term_savings_attributes: {
          id: nil, principal_amount: 10_000, term_days: 90, rate_locked: 0.12, started_at: Date.current,
          financial_product_id: 'nu_frozen_savings90'
        }
      }

      expect do
        post budgets_path, params: { budget: params }
      end.to change(Budget, :count).by(1)

      budget = Budget.last
      expect(budget.name).to eq('Ahorro Congelado 90 dias de Bryan')
      expect(budget.term_savings.first.name).to eq('Ahorro Congelado 90 dias de Bryan')
    end

    it 'crea un ahorro a plazo fijo manual (opcion "Otro") con el nombre ingresado' do
      budget_type = create_budget_type('term_saving')
      get wizard_step2_budgets_path(type: 'term_saving')

      params = {
        budget_type_id: budget_type.id,
        color_id: color.id,
        icon_id: icon.id,
        term_savings_attributes: {
          id: nil, name: 'Mi ahorro manual', principal_amount: 10_000, term_days: 90, rate_locked: 0.12,
          started_at: Date.current
        }
      }

      expect do
        post budgets_path, params: { budget: params }
      end.to change(Budget, :count).by(1)

      budget = Budget.last
      expect(budget.term_savings.first.financial_product_id).to be_blank
      expect(budget.name).to eq('Mi ahorro manual')
    end
  end
end
