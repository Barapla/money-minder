# frozen_string_literal: true

require 'rails_helper'

# El index de transacciones muestra el resumen del mes, los filtros y los
# movimientos agrupados por dia, paginados. Reemplaza la tabla generica.
RSpec.describe 'Index de transacciones', type: :request do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:types_group) { create(:group_catalog, code: 'transaction_types') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }
  let(:color) { create(:catalog, code: 'blue') }
  let(:icon) { create(:catalog) }
  let(:currency) { create(:currency) }

  def type_catalog(code)
    @type_catalogs ||= {}
    @type_catalogs[code] ||= create(:catalog, code:, value: code.capitalize, group_catalog: types_group)
  end

  def budget_for(code)
    @budgets ||= {}
    @budgets[code] ||= Budget.create!(
      name: "Cuenta #{code}", user:, budget_type: create(:catalog, code:, group_catalog: budget_types_group),
      color:, icon:, current_amount: 0
    )
  end

  # Transaction.create! dispara el after_create de RelatedTransaction en los
  # traspasos, que crea el income espejo: justo lo que el presenter debe excluir.
  def create_transaction(code, amount:, description:, **extra)
    Transaction.create!(
      user:, budget: budget_for('debit_card'), related_budget: extra[:related],
      category: extra[:category] || create(:category), currency:, color:, icon:,
      transaction_type: type_catalog(code), amount:, description:,
      transaction_date: extra.fetch(:date, Date.current)
    )
  end

  before { sign_in user }

  describe 'GET /transactions' do
    it 'agrupa los movimientos por día y los muestra con su monto con signo' do
      create_transaction('expense', amount: 250.00, description: 'Tacos')
      create_transaction('income', amount: 1000.00, description: 'Nómina')

      get transactions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tacos', 'Nómina')
      expect(response.body).to include(I18n.l(Date.current, format: :day_and_month))
      expect(response.body).to include('Hoy')
      expect(response.body).to include('−$250.00', '+$1,000.00')
    end

    it 'muestra los totales del mes separando lo interno de ingresos y gastos' do
      create_transaction('income', amount: 1000.00, description: 'Nómina')
      create_transaction('expense', amount: 400.00, description: 'Súper')
      create_transaction('transfer', amount: 300.00, description: 'Pago a tarjeta',
                                     related: budget_for('cash'))
      # El espejo del traspaso usa el catalogo 'income', ya creado arriba.

      get transactions_path

      expect(response.body).to include('Ingresos', 'Gastos', 'Neto del mes', 'Movimientos internos')
      expect(response.body).to include('$1,000.00') # ingresos
      expect(response.body).to include('$400.00')   # gastos
      expect(response.body).to include('+$600.00')  # neto: el traspaso no resta
      expect(response.body).to include('$300.00')   # movimientos internos
    end

    it 'cuenta cada traspaso una sola vez, no también su espejo' do
      type_catalog('income')
      create_transaction('transfer', amount: 300.00, description: 'Traspaso a fondo',
                                     related: budget_for('cash'))

      # El after_create dejo dos filas en la BD; la vista debe mostrar una.
      expect(user.transactions.count).to eq(2)

      get transactions_path

      expect(response.body.scan('Traspaso a fondo').size).to eq(1)
      expect(response.body).to include('Todo · 1')
    end

    it 'filtra por tipo sin perder el contador de los demás chips' do
      create_transaction('expense', amount: 250.00, description: 'Tacos')
      create_transaction('income', amount: 1000.00, description: 'Quincena de septiembre')

      get transactions_path(type: 'expense')

      expect(response.body).to include('Tacos')
      expect(response.body).not_to include('Quincena de septiembre')
      expect(response.body).to include('Ingresos · 1')
    end

    it 'busca por descripción y por nombre de categoría' do
      comida = create(:category, name: 'Comida')
      create_transaction('expense', amount: 250.00, description: 'Tacos', category: comida)
      create_transaction('expense', amount: 90.00, description: 'Café')

      get transactions_path(q: 'comi')

      expect(response.body).to include('Tacos')
      expect(response.body).not_to include('Café')
    end

    it 'filtra por cuenta' do
      create_transaction('expense', amount: 250.00, description: 'Tacos')

      get transactions_path(budget_id: budget_for('cash').id)

      expect(response.body).not_to include('Tacos')
      expect(response.body).to include('Ningún movimiento coincide')
    end

    it 'pagina dentro del mes y respeta el tamaño de página' do
      12.times { |i| create_transaction('expense', amount: 10.00 + i, description: "Gasto #{i}") }

      get transactions_path

      expect(response.body).to include('Mostrando')
      expect(response.body).to include('1–10')

      get transactions_path(page: 2)

      expect(response.body).to include('11–12')
    end

    it 'navega a otro mes y ahí no muestra los movimientos de este' do
      create_transaction('expense', amount: 250.00, description: 'Tacos')
      anterior = Date.current.prev_month

      get transactions_path(month: anterior.strftime('%Y-%m'))

      expect(response.body).not_to include('Tacos')
      expect(response.body).to include(I18n.l(anterior.beginning_of_month, format: :month_year))
      expect(response.body).to include('Volver al mes actual')
    end

    it 'ignora un mes inválido y se queda en el actual' do
      get transactions_path(month: 'no-es-un-mes')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.l(Date.current.beginning_of_month, format: :month_year))
    end

    it 'muestra el estado vacío cuando el mes no tiene movimientos' do
      get transactions_path

      expect(response.body).to include('Todavía no hay movimientos este mes')
    end
  end
end
