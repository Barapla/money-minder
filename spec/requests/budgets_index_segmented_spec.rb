# frozen_string_literal: true

require 'rails_helper'

# FEAT-032: el index de presupuestos se segmenta en secciones por tipo de cuenta
# (tarjeta de credito, tarjeta de debito, fondo de ahorro) en vez de una unica lista.
RSpec.describe 'Index segmentado de presupuestos (FEAT-032)', type: :request do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }

  def create_budget_type(code)
    create(:catalog, code:, group_catalog: budget_types_group)
  end

  # Atributos anidados minimos para que credit_card/savings_fund sean renderizables:
  # sin cutting_day, BudgetPresenter#debt_amount revienta calculando el ciclo actual,
  # y compound_frequency_id/account_type_id son NOT NULL en savings_funds.
  def nested_attrs_for(code)
    case code
    when 'credit_card'
      { credit_card_attributes: { initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5 } }
    when 'savings_fund'
      { savings_fund_attributes: { compound_frequency_id: create(:catalog).id, account_type_id: create(:catalog).id } }
    else
      {}
    end
  end

  # Budget.create! (no la factory :budget) para que after_initialize corra con
  # budget_type ya asignado y construya credit_card/savings_fund en la misma llamada
  # (ver Budget#build_budget_type_if_needed).
  def create_budget(code, name:)
    Budget.create!(
      { name:, user:, budget_type: create_budget_type(code), color:, icon:, current_amount: 0 }
        .merge(nested_attrs_for(code))
    )
  end

  before { sign_in user }

  describe 'GET /budgets' do
    it 'CA1, CA2, CA3, CA4: agrupa por tipo con las secciones en el orden esperado' do
      create_budget('credit_card', name: 'Tarjeta Nu')
      create_budget('debit_card', name: 'Debito Klar')
      create_budget('savings_fund', name: 'Ahorro BBVA')

      get budgets_path

      expect(response).to have_http_status(:ok)
      expect(response.body.index('Tarjetas de Crédito'))
        .to be < response.body.index('Tarjetas de Débito')
      expect(response.body.index('Tarjetas de Débito'))
        .to be < response.body.index('Fondos de Ahorro')
      expect(response.body).to include('Tarjeta Nu')
      expect(response.body).to include('Debito Klar')
      expect(response.body).to include('Ahorro BBVA')
    end

    it 'manda la seccion de efectivo hasta el final, despues de los demas tipos' do
      create_budget('cash', name: 'Efectivo suelto')
      create_budget('credit_card', name: 'Tarjeta Nu')
      create_budget('savings_fund', name: 'Ahorro BBVA')

      get budgets_path

      expect(response.body.index('Tarjetas de Crédito')).to be < response.body.index('Efectivo suelto')
      expect(response.body.index('Fondos de Ahorro')).to be < response.body.index('Efectivo suelto')
    end

    it 'CA5: no muestra la seccion de un tipo sin presupuestos' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      expect(response.body).to include('Tarjetas de Crédito')
      expect(response.body).not_to include('Tarjetas de Débito')
      expect(response.body).not_to include('Fondos de Ahorro')
    end

    it 'CA6: muestra el contador de presupuestos en el encabezado de cada seccion' do
      create_budget('credit_card', name: 'Tarjeta Nu')
      create_budget('credit_card', name: 'Tarjeta BBVA')

      get budgets_path

      expect(response.body).to include('2 presupuestos')
    end

    it 'CA7: muestra el mensaje de estado vacio cuando no hay presupuestos' do
      get budgets_path

      expect(response.body).to include('No hay presupuestos')
      expect(response.body).not_to include('Tarjetas de Crédito')
    end

    it 'no incluye presupuestos de otro usuario en el agrupamiento' do
      other_user = create(:user)
      Budget.create!(name: 'Ajeno', user: other_user, budget_type: create_budget_type('credit_card'), color:, icon:,
                     current_amount: 0)

      get budgets_path

      expect(response.body).to include('No hay presupuestos')
      expect(response.body).not_to include('Ajeno')
    end
  end

  # Tabs + paginacion pedidas en el review de FEAT-032: cada seccion pagina via AJAX
  # contra POST /budgets/budgets_table, filtrando por tipo y por usuario.
  describe 'POST /budgets/budgets_table' do
    it 'pagina solo los presupuestos del tipo pedido, del usuario actual' do
      create_budget('credit_card', name: 'Tarjeta Nu')
      create_budget('savings_fund', name: 'Ahorro BBVA')
      other_user = create(:user)
      Budget.create!(name: 'Ajeno', user: other_user, budget_type: create_budget_type('credit_card'), color:, icon:,
                     current_amount: 0)

      post budgets_table_budgets_path(type: 'credit_card'),
           params: { id: 'budget-section-credit_card', page: 1, perPage: 10 },
           as: :json, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tarjeta Nu')
      expect(response.body).not_to include('Ahorro BBVA')
      expect(response.body).not_to include('Ajeno')
    end
  end
end
