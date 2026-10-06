# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deudas', type: :request do
  let(:user) { create(:user) }
  let(:catalog) { create(:catalog) }

  # ObligatoryPayment exige category, color e icon, y ReminderBuilder los resuelve
  # del catalogo. En dev vienen del seed; aqui hay que ponerlos.
  before do
    create(:group_catalog, code: 'recurrenceable_types').catalogs.create!(code: 'obligatory_payment',
                                                                          value: 'Pago obligatorio')
    create(:group_catalog, code: 'frequency_types').catalogs.create!(code: 'weekly', value: 'Semanal')
    create(:group_catalog, code: 'colors').catalogs.create!(code: 'purple', value: 'purple-500')
    create(:group_catalog, code: 'transaction_icons').catalogs.create!(code: 'personal_loans', value: '🏦')
    create(:category, name: 'Préstamos personales')
    sign_in user
  end

  describe 'GET /debts' do
    it 'separa lo que me deben de lo que debo, con el neto' do
      create(:debt, user:, name: 'Préstamo a Luis', principal_amount: 25_000)
      create(:debt, :payable, user:, name: 'Tarjeta de mamá', principal_amount: 4000)

      get debts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Préstamo a Luis', 'Tarjeta de mamá')
      expect(response.body).to include('Te deben', 'Debes', 'Posición neta')
      expect(response.body).to include('$25,000.00', '$4,000.00')
      expect(response.body).to include('$21,000.00') # neto
    end

    it 'muestra el estado vacío sin deudas' do
      get debts_path

      expect(response.body).to include('Todavía no registras deudas')
    end
  end

  describe 'GET /debts/:id' do
    it 'muestra el avance y los abonos ligados' do
      debt = create(:debt, user:, name: 'Préstamo a Luis', principal_amount: 25_000)

      get debt_path(debt)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Préstamo a Luis')
      expect(response.body).to include('Plan de pagos')
      expect(response.body).to include('Sin abonos todavía')
    end

    it 'no deja ver la deuda de otro usuario' do
      ajena = create(:debt, user: create(:user))

      get debt_path(ajena)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /debts' do
    # El usuario eligio que la deuda genere su recordatorio: con plan de pagos
    # tiene que aparecer solo en el calendario.
    it 'crea la deuda y le genera su recordatorio' do
      expect do
        post debts_path, params: {
          debt: { direction: 'receivable', name: 'Préstamo a Luis', counterparty: 'Luis',
                  principal_amount: 25_000, installment_amount: 250,
                  started_on: Date.current, expected_end_on: Date.current + 2.years },
          frequency: 'weekly'
        }
      end.to change(Debt, :count).by(1).and change(ObligatoryPayment, :count).by(1)

      debt = Debt.last
      expect(debt.obligatory_payment).to be_present
      expect(debt.obligatory_payment.reminder_type).to eq('income')
      expect(debt.obligatory_payment.amount).to eq(250)
      expect(debt.obligatory_payment.recurrence.frequency_type.code).to eq('weekly')
    end

    it 'sin plan de pagos no genera recordatorio' do
      expect do
        post debts_path, params: {
          debt: { direction: 'payable', name: 'Le debo a Ana', principal_amount: 800,
                  started_on: Date.current }
        }
      end.to change(Debt, :count).by(1).and(not_change(ObligatoryPayment, :count))

      expect(Debt.last.obligatory_payment).to be_nil
    end

    # El caso "solo quiero acordarme de que fulano me debe".
    it 'crea una deuda suelta sin fechas ni recordatorio' do
      expect do
        post debts_path, params: {
          debt: { direction: 'receivable', name: 'Luis me debe una comida',
                  counterparty: 'Luis', principal_amount: 350 }
        }
      end.to change(Debt, :count).by(1).and(not_change(ObligatoryPayment, :count))

      debt = Debt.last
      expect(debt.started_on).to be_nil
      expect(debt.obligatory_payment).to be_nil
      expect(debt.remaining_amount).to eq(350)
    end

    it 'muestra una deuda suelta sin reventar por la fecha vacía' do
      debt = create(:debt, user:, name: 'Sin fechas', started_on: nil, installment_amount: nil)

      get debt_path(debt)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sin fechas')
      expect(response.body).to include('Sin plan de pagos')
    end

    it 'rechaza un monto original en cero' do
      expect do
        post debts_path, params: { debt: { direction: 'receivable', name: 'Vacía',
                                           principal_amount: 0, started_on: Date.current } }
      end.not_to change(Debt, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # El camino que usa el formulario: `debt_id` y `debt_amount` son atajos que
  # crean la DebtAllocation al guardar la transaccion.
  describe 'alta de transacción ligada a una deuda' do
    let(:debt) { create(:debt, user:, principal_amount: 25_000) }

    def budget
      @budget ||= Budget.create!(
        name: 'Cuenta', user:,
        budget_type: create(:catalog, code: 'debit_card', group_catalog: create(:group_catalog, code: 'budget_types')),
        color: create(:catalog), icon: create(:catalog), current_amount: 50_000
      )
    end

    # currency_id no se permite en transaction_params: la moneda la pone
    # Transaction#set_default_values con Currency.default, que busca MXN.
    def post_transaction(amount, debt_amount: nil)
      create(:currency, code: 'MXN') unless Currency.default
      income = create(:catalog, code: 'income', value: 'Ingreso',
                                group_catalog: create(:group_catalog, code: 'transaction_types'))
      post transactions_path, params: {
        transaction: base_transaction_params(income).merge(amount:, debt_id: debt.id, debt_amount:)
      }
    end

    def base_transaction_params(income)
      { transaction_type_id: income.id, description: 'Abono', transaction_date: Date.current,
        category_id: create(:category).id, budget_id: budget.id,
        icon_id: create(:catalog).id, color_id: create(:catalog).id }
    end

    it 'abona el monto completo cuando no se especifica otro' do
      post_transaction(250)

      expect(debt.reload.paid_amount).to eq(250)
    end

    it 'abona solo la parte indicada cuando el resto era de otra cosa' do
      post_transaction(1250, debt_amount: 250)

      expect(debt.reload.paid_amount).to eq(250)
      expect(debt.debt_allocations.first).to be_partial
    end

    it 'abona más que el movimiento cuando se neteó algo' do
      post_transaction(215, debt_amount: 250)

      expect(debt.reload.paid_amount).to eq(250)
      expect(debt.debt_allocations.first).to be_symbolic
    end
  end

  describe 'PATCH /debts/:id/settle' do
    it 'la marca liquidada' do
      debt = create(:debt, user:)

      patch settle_debt_path(debt)

      expect(debt.reload).to be_settled
    end
  end

  describe 'DELETE /debts/:id' do
    it 'se lleva su recordatorio' do
      debt = create(:debt, user:)
      DebtServices::ReminderBuilder.new(debt, frequency: 'weekly').call

      expect { delete debt_path(debt.reload) }.to change(ObligatoryPayment, :count).by(-1)
    end
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
