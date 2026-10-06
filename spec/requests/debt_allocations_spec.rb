# frozen_string_literal: true

require 'rails_helper'

# Ligar movimientos se hace desde la deuda, no desde el alta de la transaccion:
# es ahi donde se ve el saldo.
RSpec.describe 'Abonos de una deuda', type: :request do
  let(:user) { create(:user) }
  let(:debt) { create(:debt, user:, principal_amount: 25_000) }

  def budget
    @budget ||= Budget.create!(
      name: 'Cuenta', user:,
      budget_type: create(:catalog, code: 'debit_card', group_catalog: create(:group_catalog, code: 'budget_types')),
      color: create(:catalog), icon: create(:catalog), current_amount: 50_000
    )
  end

  def income_type
    @income_type ||= create(:catalog, code: 'income', value: 'Ingreso',
                                      group_catalog: create(:group_catalog, code: 'transaction_types'))
  end

  def transaction_for(amount, description: 'Pago Luis')
    Transaction.create!(
      user:, budget:, category: create(:category), currency: create(:currency),
      color: create(:catalog), icon: create(:catalog), transaction_type: income_type,
      amount:, description:, transaction_date: Date.current
    )
  end

  before { sign_in user }

  describe 'POST /debts/:debt_id/abonos' do
    it 'liga un movimiento con el monto que abona' do
      movimiento = transaction_for(1250)

      post debt_debt_allocations_path(debt), params: {
        debt_allocation: { transaction_id: movimiento.id, amount: 250 }
      }

      expect(response).to redirect_to(debt)
      expect(debt.reload.paid_amount).to eq(250)
      expect(debt.debt_allocations.first).to be_partial
    end

    it 'no deja ligar el movimiento de otro usuario' do
      ajena = create(:user)
      budget_ajeno = Budget.create!(
        name: 'X', user: ajena, current_amount: 0,
        budget_type: create(:catalog, code: 'cash', group_catalog: create(:group_catalog, code: 'bt2')),
        color: create(:catalog), icon: create(:catalog)
      )
      movimiento = Transaction.create!(
        user: ajena, budget: budget_ajeno,
        category: create(:category), currency: create(:currency), color: create(:catalog),
        icon: create(:catalog), transaction_type: income_type, amount: 100,
        description: 'Ajena', transaction_date: Date.current
      )

      expect do
        post debt_debt_allocations_path(debt), params: {
          debt_allocation: { transaction_id: movimiento.id, amount: 100 }
        }
      end.not_to change(DebtAllocation, :count)

      expect(response).to have_http_status(:not_found)
    end

    it 'rechaza ligar dos veces el mismo movimiento a la misma deuda' do
      movimiento = transaction_for(250)
      DebtAllocation.create!(debt:, transaction_record: movimiento, amount: 250)

      expect do
        post debt_debt_allocations_path(debt), params: {
          debt_allocation: { transaction_id: movimiento.id, amount: 100 }
        }
      end.not_to change(DebtAllocation, :count)
    end
  end

  describe 'PATCH /debts/:debt_id/abonos/:id' do
    it 'corrige cuánto abona, incluso por encima del movimiento' do
      movimiento = transaction_for(215)
      allocation = DebtAllocation.create!(debt:, transaction_record: movimiento, amount: 215)

      patch debt_debt_allocation_path(debt, allocation), params: {
        debt_allocation: { amount: 250 }
      }

      expect(allocation.reload.amount).to eq(250)
      expect(allocation).to be_symbolic
      expect(debt.reload.paid_amount).to eq(250)
    end
  end

  describe 'DELETE /debts/:debt_id/abonos/:id' do
    it 'desliga sin borrar la transacción' do
      movimiento = transaction_for(250)
      allocation = DebtAllocation.create!(debt:, transaction_record: movimiento, amount: 250)

      expect { delete debt_debt_allocation_path(debt, allocation) }.not_to change(Transaction, :count)

      expect(debt.reload.paid_amount).to eq(0)
      expect(movimiento.reload).to be_persisted
    end
  end

  describe 'GET /debts/:id' do
    it 'ofrece ligar los movimientos del tipo que le toca a la deuda' do
      transaction_for(250, description: 'Pago Luis prestamo')

      get debt_path(debt)

      expect(response.body).to include('Ligar un movimiento')
      expect(response.body).to include('Pago Luis prestamo')
    end
  end
end
