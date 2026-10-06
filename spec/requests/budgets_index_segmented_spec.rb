# frozen_string_literal: true

require 'rails_helper'

# El index agrupa las cuentas por lo que son (uso diario, inversion, plazo fijo)
# y saca las tarjetas de credito a su propia tabla. Reemplaza las pestanas por
# tipo de FEAT-032.
RSpec.describe 'Index de presupuestos', type: :request do
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
    it 'agrupa el dinero por uso y separa las tarjetas de crédito' do
      create_budget('debit_card', name: 'Debito Klar')
      create_budget('savings_fund', name: 'Ahorro BBVA')
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tu dinero')
      expect(response.body.index('Uso diario')).to be < response.body.index('Inversión')
      expect(response.body.index('Inversión')).to be < response.body.index('Tus tarjetas de crédito')
      expect(response.body).to include('Debito Klar', 'Ahorro BBVA', 'Tarjeta Nu')
    end

    it 'muestra los totales de arriba' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      expect(response.body).to include('Patrimonio neto')
      expect(response.body).to include('Utilización total')
      expect(response.body).to include('Rinde al año')
    end

    it 'pliega las cuentas en ceros detrás de un botón, con su contador' do
      create_budget('debit_card', name: 'Debito vacio')

      get budgets_path

      expect(response.body).to include('Ver la que está en ceros')
      expect(response.body).to include('Sin usar')
    end

    it 'abre la tabla de tarjetas solo con las que deben' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      # Sin deuda, la fila va oculta y se resume en el pie plegable.
      expect(response.body).to include('1 tarjeta en ceros')
      expect(response.body).to include('de línea sin usar')
      expect(response.body).to include('Ver las 1')
    end

    # El orden del markup no es cosmetico: budget-filters#sortAccounts reinserta
    # las filas contra su vecino de la derecha asumiendo que ocupan un bloque
    # contiguo, con la fila-resumen y el pie despues. Si el bloque se parte, el
    # boton de desplegar las que estan en ceros vuelve a subirse hasta arriba.
    it 'deja el resumen de tarjetas en ceros y el pie después de las filas' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      fila = response.body.index('Tarjeta Nu')
      resumen = response.body.index('1 tarjeta en ceros')
      pie = response.body.index('Nueva tarjeta')
      expect(fila).to be < resumen
      expect(resumen).to be < pie
    end

    it 'avisa cuando ninguna tarjeta pasa del 30% de su línea' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      expect(response.body).to include('Ninguna tarjeta pasa del 30%')
    end

    it 'saca el efectivo de su propia sección: ahora vive en uso diario' do
      create_budget('cash', name: 'Efectivo suelto')

      get budgets_path

      expect(response.body).to include('Uso diario')
      expect(response.body).to include('Efectivo suelto')
    end

    it 'ofrece buscar, ordenar y filtrar sin volver al servidor' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      expect(response.body).to include('data-controller="budget-filters"')
      expect(response.body).to include('Solo con saldo')
      expect(response.body).to include('Ordenar:')
    end

    it 'muestra un chip por tipo, incluso con cero cuentas' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      # El diseño lista todos los tipos; los que no tienes salen en cero.
      expect(response.body).to include('Tarjeta de crédito · 1')
      expect(response.body).to include('Plazo fijo · 0')
      expect(response.body).to include('Efectivo · 0')
      expect(response.body).to include('Todas · 1')
    end

    it 'invita a abrir un plazo fijo cuando no hay ninguno' do
      create_budget('credit_card', name: 'Tarjeta Nu')

      get budgets_path

      expect(response.body).to include('No tienes cuentas a plazo fijo')
    end

    it 'muestra el estado vacio cuando el usuario no tiene presupuestos' do
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
