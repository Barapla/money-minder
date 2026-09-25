# frozen_string_literal: true

require 'rails_helper'

# El detalle de una transaccion: hero, impacto en el saldo, ciclo de tarjeta,
# peso en su categoria, recurrencia, relacionadas y metadatos.
RSpec.describe 'Detalle de transacción', type: :request do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:types_group) { create(:group_catalog, code: 'transaction_types') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }
  let(:color) { create(:catalog, code: 'blue') }
  let(:icon) { create(:catalog, value: '📡') }
  let(:currency) { create(:currency) }
  let(:category) { create(:category, name: 'Internet y teléfono') }

  def type_catalog(code)
    @type_catalogs ||= {}
    @type_catalogs[code] ||= create(:catalog, code:, value: code.capitalize, group_catalog: types_group)
  end

  def debit_budget
    @debit_budget ||= Budget.create!(
      name: 'Didi Cuenta', user:, budget_type: create(:catalog, code: 'debit_card', group_catalog: budget_types_group),
      color:, icon:, current_amount: 20_000
    )
  end

  def credit_budget
    @credit_budget ||= Budget.create!(
      name: 'Klar', user:, budget_type: create(:catalog, code: 'credit_card', group_catalog: budget_types_group),
      color:, icon:, current_amount: 0,
      credit_card_attributes: { initial_debt: 0, limit_amount: 21_000, cutting_day: 7, payment_due_days: 20 }
    )
  end

  def create_transaction(code, amount:, description:, budget: debit_budget, **extra)
    Transaction.create!(
      user:, budget:, category: extra[:category] || category, currency:, color:, icon:,
      transaction_type: type_catalog(code), amount:, description:,
      transaction_date: extra.fetch(:date, Date.current)
    )
  end

  # CycleRecalculationService busca el Status por el lifecycle_status_code del
  # ciclo ('open', 'pending_payment', 'closed', 'overdue'); sin esas filas el alta
  # de una transaccion a tarjeta revienta con "Status es requerido".
  before do
    statuses_group = create(:group_catalog, code: 'credit_card_cycle_statuses')
    %w[open pending_payment closed overdue].each do |code|
      Status.find_or_create_by!(code:) do |status|
        status.name = code.humanize
        status.group_catalog = statuses_group
      end
    end
    sign_in user
  end

  describe 'GET /transactions/:id' do
    it 'muestra el hero con el monto con signo, la categoría y la cuenta' do
      transaction = create_transaction('expense', amount: 2172.59, description: 'Telcel madre')

      get transaction_path(transaction)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Telcel madre')
      expect(response.body).to include('−$2,172.59')
      expect(response.body).to include('Internet y teléfono')
      expect(response.body).to include('Didi Cuenta')
      expect(response.body).to include('Cargado a')
    end

    it 'lleva miga de pan hacia el índice y hacia el mes' do
      transaction = create_transaction('expense', amount: 100.00, description: 'Café')

      get transaction_path(transaction)

      expect(response.body).to include(transactions_path)
      expect(response.body).to include(I18n.l(Date.current.beginning_of_month, format: :month_year))
    end

    it 'muestra el impacto en el saldo, con el antes y el después' do
      transaction = create_transaction('expense', amount: 500.00, description: 'Súper')

      get transaction_path(transaction)

      expect(response.body).to include('Impacto en el presupuesto')
      expect(response.body).to include('Saldo anterior', 'Saldo posterior')
      expect(response.body).to include('$20,000.00') # antes
      expect(response.body).to include('$19,500.00') # después
    end

    it 'pondera el movimiento dentro de su categoría en el mes' do
      create_transaction('expense', amount: 1154.03, description: 'Telcel mio')
      transaction = create_transaction('expense', amount: 2172.59, description: 'Telcel madre')

      get transaction_path(transaction)

      expect(response.body).to include('$3,326.62') # total de la categoría
      expect(response.body).to include('65.3%')     # 2172.59 de 3326.62
      expect(response.body).to include('Promedio por movimiento')
    end

    it 'lista los otros movimientos del mismo día en la misma categoría' do
      create_transaction('expense', amount: 1154.03, description: 'Telcel mio')
      transaction = create_transaction('expense', amount: 2172.59, description: 'Telcel madre')

      get transaction_path(transaction)

      expect(response.body).to include('Transacciones relacionadas')
      expect(response.body).to include('Telcel mio')
    end

    it 'muestra los metadatos con el origen manual' do
      transaction = create_transaction('expense', amount: 100.00, description: 'Café')

      get transaction_path(transaction)

      expect(response.body).to include('Metadatos')
      expect(response.body).to include('Registro manual')
      expect(response.body).to include(transaction.uuid.truncate(22))
    end

    context 'cargada a una tarjeta de crédito' do
      it 'muestra el ciclo en el que cayó y la utilización de la línea' do
        transaction = create_transaction('expense', amount: 2172.59, description: 'Telcel madre',
                                                    budget: credit_budget)

        get transaction_path(transaction)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Ciclo en el que cayó')
        expect(response.body).to include('corta el 7 de cada mes')
        expect(response.body).to include('Este cargo, contra tu línea de $21,000.00')
        expect(response.body).to include('Techo sano 30%')
      end
    end

    # Regresion: `Budget#current_amount` de una tarjeta es el CREDITO DISPONIBLE,
    # no la deuda. Dividir ese numero entre el limite daba el porcentaje libre
    # (77% en una tarjeta con 23% de uso) etiquetado como "utilizacion".
    context 'utilización de una tarjeta' do
      it 'la calcula sobre la deuda, no sobre el crédito disponible' do
        transaction = create_transaction('expense', amount: 2300.00, description: 'Compra',
                                                    budget: credit_budget)
        card = credit_budget.credit_card

        get transaction_path(transaction)

        presenter = TransactionShowPresenter.new(transaction.reload)
        expect(presenter.balance_after).to be_within(0.01).of(card.reload.current_debt)
        expect(presenter.utilization_after).to be_within(0.05).of(card.utilization_percentage)
        # 2300 de una linea de 21000 = 10.95%, no el 89% que quedaba libre.
        expect(presenter.utilization_after).to be_within(0.1).of(11.0)
        expect(response.body).to include('Deuda posterior')

        # El titular de la pagina es lo que pesa ESTE cargo contra la linea,
        # no la utilizacion total de la tarjeta.
        expect(presenter.share_of_limit).to be_within(0.1).of(11.0)
        expect(response.body).to include('Este cargo, contra tu línea de $21,000.00')
        expect(response.body).to include('Tu utilización pasó de 0.0% a 11.0%')
      end
    end

    # La barra va apilada sobre la linea completa: un tramo para donde ya estaba
    # la deuda y otro, visible y aparte, para lo que movio este movimiento. Antes
    # pintaba la utilizacion total con la anterior encima, asi que el aporte del
    # cargo quedaba como una rendija invisible.
    context 'barra de la línea de crédito' do
      it 'apila el tramo del cargo encima de la deuda que ya había' do
        create_transaction('expense', amount: 4200.00, description: 'Previo', budget: credit_budget)
        transaction = create_transaction('expense', amount: 2100.00, description: 'Este',
                                                    budget: credit_budget)

        get transaction_path(transaction)

        seg = TransactionShowPresenter.new(transaction.reload).utilization_segments
        expect(seg[:base]).to be_within(0.1).of(20.0)   # 4200 de 21000
        expect(seg[:change]).to be_within(0.1).of(10.0) # 2100 de 21000
        expect(seg[:direction]).to eq(:up)
        # Los dos tramos juntos son la utilizacion posterior.
        expect(seg[:base] + seg[:change]).to be_within(0.1).of(30.0)
      end

      it 'en un pago pinta el tramo liberado y no lo llama cargo' do
        create_transaction('expense', amount: 6300.00, description: 'Compra', budget: credit_budget)
        pago = create_transaction('income', amount: 2100.00, description: 'Pago de tarjeta',
                                            budget: credit_budget)

        get transaction_path(pago)

        presenter = TransactionShowPresenter.new(pago.reload)
        expect(presenter.reduces_debt?).to be(true)
        expect(presenter.utilization_segments[:direction]).to eq(:down)
        expect(response.body).to include('Este pago, contra tu línea')
        expect(response.body).not_to include('Este cargo, contra tu línea')
      end
    end

    context 'ligada a deudas' do
      it 'muestra a qué deuda abona y cuánto quedó sin asignar' do
        debt = create(:debt, user:, name: 'Préstamo a Luis', principal_amount: 25_000)
        transaction = create_transaction('income', amount: 1250.00, description: 'Pago luis deuda')
        DebtAllocation.create!(debt:, transaction_record: transaction, amount: 250)

        get transaction_path(transaction)

        expect(response.body).to include('Abona a deudas')
        expect(response.body).to include('Préstamo a Luis')
        expect(response.body).to include('$1,000.00 de este movimiento no abonan a ninguna deuda')
      end

      it 'avisa cuando abona más de lo que dice el movimiento' do
        debt = create(:debt, user:, name: 'Préstamo a Luis', principal_amount: 25_000)
        transaction = create_transaction('income', amount: 215.00, description: 'Pago Luis')
        DebtAllocation.create!(debt:, transaction_record: transaction, amount: 250)

        get transaction_path(transaction)

        expect(response.body).to include('Abona $35.00 más de lo que dice el movimiento')
      end

      it 'reparte entre dos deudas el depósito que trae las dos' do
        prestamo = create(:debt, user:, name: 'Préstamo a Luis', principal_amount: 25_000)
        spotify = create(:debt, user:, name: 'Spotify anual de Luis', principal_amount: 467)
        transaction = create_transaction('income', amount: 260.00, description: 'Pago luis prestamo')
        DebtAllocation.create!(debt: prestamo, transaction_record: transaction, amount: 250)
        DebtAllocation.create!(debt: spotify, transaction_record: transaction, amount: 10)

        get transaction_path(transaction)

        expect(response.body).to include('Préstamo a Luis', 'Spotify anual de Luis')
        expect(response.body).to include('se reparte entre 2 deudas')
        expect(response.body).not_to include('no abonan a ninguna deuda')
      end
    end

    context 'sin historial de saldo' do
      # transaction_history se crea en un after_create; las filas viejas pueden no
      # tenerlo y la pagina no debe reventar por eso.
      it 'omite el bloque de impacto en vez de romperse' do
        transaction = create_transaction('expense', amount: 100.00, description: 'Café')
        transaction.transaction_history.destroy!

        get transaction_path(transaction.reload)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Impacto en el presupuesto')
        expect(response.body).to include('Café')
      end
    end
  end
end
