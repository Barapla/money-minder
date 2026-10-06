# frozen_string_literal: true

require 'rails_helper'

# El saldo de una deuda no se guarda: se calcula sumando las transacciones
# ligadas. Eso es lo que hace que un abono extra o uno de menos cuadren solos.
RSpec.describe Debt do
  let(:user) { create(:user) }
  let(:types_group) { create(:group_catalog, code: 'transaction_types') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }
  let(:catalog) { create(:catalog) }

  def budget
    @budget ||= Budget.create!(
      name: 'Cuenta', user:, budget_type: create(:catalog, code: 'debit_card', group_catalog: budget_types_group),
      color: catalog, icon: catalog, current_amount: 100_000
    )
  end

  # `applied` vacio = abona el monto completo del movimiento.
  def pay(debt, amount, applied: nil, code: 'income')
    Transaction.create!(
      user:, budget:, category: create(:category), currency: create(:currency),
      color: catalog, icon: catalog,
      transaction_type: create(:catalog, code:, value: code, group_catalog: types_group),
      amount:, description: "Abono #{amount}", transaction_date: Date.current,
      debt_id: debt.id, debt_amount: applied
    )
  end

  describe 'saldo' do
    subject(:debt) { create(:debt, user:, principal_amount: 25_000, installment_amount: 250) }

    it 'arranca sin nada pagado' do
      expect(debt.paid_amount).to eq(0)
      expect(debt.remaining_amount).to eq(25_000)
      expect(debt.progress_percentage).to eq(0.0)
    end

    it 'descuenta cada abono ligado' do
      pay(debt, 250)
      pay(debt, 1000)

      expect(debt.reload.paid_amount).to eq(1250)
      expect(debt.remaining_amount).to eq(23_750)
      expect(debt.progress_percentage).to eq(5.0)
    end

    # El caso que motivo el modulo: Luis abona de mas para liquidar antes.
    it 'recalcula los pagos que faltan cuando hay un abono grande' do
      pay(debt, 250)
      expect(debt.reload.remaining_installments).to eq(99)

      pay(debt, 10_000)
      expect(debt.reload.remaining_installments).to eq(59)
    end

    it 'no deja el saldo en negativo cuando se paga de más' do
      pay(debt, 30_000)

      expect(debt.reload.remaining_amount).to eq(0)
      expect(debt.overpaid_amount).to eq(5000)
      expect(debt.progress_percentage).to eq(100.0)
      expect(debt).to be_fully_paid
    end

    it 'sin plan de pagos no habla de cuotas' do
      suelta = create(:debt, user:, installment_amount: nil)

      expect(suelta.installments?).to be(false)
      expect(suelta.remaining_installments).to be_nil
    end
  end

  describe 'dirección' do
    it 'lo que me deben entra como ingreso' do
      debt = create(:debt, user:, direction: :receivable)

      expect(debt.reminder_type).to eq(:income)
      expect(debt.transaction_type_code).to eq('income')
    end

    it 'lo que debo sale como gasto' do
      debt = create(:debt, :payable, user:)

      expect(debt.reminder_type).to eq(:payment)
      expect(debt.transaction_type_code).to eq('expense')
    end
  end

  describe 'validaciones' do
    it 'exige monto original positivo' do
      expect(build(:debt, user:, principal_amount: 0)).not_to be_valid
    end

    # Una deuda puede ser solo un apunte de "fulano me debe", sin fechas ni plan.
    it 'acepta una deuda sin fecha ni plan de pagos' do
      suelta = build(:debt, user:, started_on: nil, installment_amount: nil, expected_end_on: nil)

      expect(suelta).to be_valid
      expect(suelta.installments?).to be(false)
    end

    it 'exige fecha de inicio solo cuando hay pago acordado' do
      con_plan = build(:debt, user:, started_on: nil, installment_amount: 250)

      expect(con_plan).not_to be_valid
      expect(con_plan.errors[:started_on]).to be_present
    end

    it 'no acepta un término anterior al inicio' do
      debt = build(:debt, user:, started_on: Date.current, expected_end_on: Date.current - 1)

      expect(debt).not_to be_valid
      expect(debt.errors[:expected_end_on]).to be_present
    end
  end

  # Los dos casos reales que motivaron separar el monto aplicado del monto del
  # movimiento: a veces la transaccion vale mas que lo que abona, a veces menos.
  describe 'monto aplicado distinto al de la transacción' do
    subject(:debt) { create(:debt, user:, principal_amount: 25_000, installment_amount: 250) }

    it 'abona solo una parte cuando el resto era de otra cosa' do
      pay(debt, 1250, applied: 250)

      expect(debt.reload.paid_amount).to eq(250)
      allocation = debt.debt_allocations.first
      expect(allocation.unallocated_amount).to eq(1000)
      expect(allocation).to be_partial
    end

    it 'abona de más cuando se neteó algo que se debía al otro' do
      pay(debt, 215, applied: 250)

      expect(debt.reload.paid_amount).to eq(250)
      allocation = debt.debt_allocations.first
      expect(allocation.unallocated_amount).to eq(-35)
      expect(allocation).to be_symbolic
    end

    it 'reparte una misma transacción entre dos deudas' do
      otra = create(:debt, user:, principal_amount: 3000)
      transaction = pay(debt, 1250, applied: 250)
      DebtAllocation.create!(debt: otra, transaction_record: transaction, amount: 1000)

      expect(debt.reload.paid_amount).to eq(250)
      expect(otra.reload.paid_amount).to eq(1000)
      expect(transaction.debt_allocations.sum(:amount)).to eq(1250)
    end

    it 'no permite dos aplicaciones de la misma deuda a la misma transacción' do
      transaction = pay(debt, 250)
      duplicada = DebtAllocation.new(debt:, transaction_record: transaction, amount: 100)

      expect(duplicada).not_to be_valid
    end
  end

  describe 'al borrar' do
    it 'la deuda suelta las transacciones en vez de borrarlas' do
      debt = create(:debt, user:)
      pay(debt, 250)

      expect { debt.destroy }.not_to change(Transaction, :count)
      expect(DebtAllocation.count).to eq(0)
    end

    it 'borrar la transacción quita lo que abonaba' do
      debt = create(:debt, user:)
      transaction = pay(debt, 250)
      expect(debt.reload.paid_amount).to eq(250)

      transaction.destroy

      expect(debt.reload.paid_amount).to eq(0)
    end
  end
end
