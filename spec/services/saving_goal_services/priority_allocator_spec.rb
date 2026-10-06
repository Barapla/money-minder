# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SavingGoalServices::PriorityAllocator, type: :service do
  let(:user) { create(:user) }
  subject(:allocator) { described_class.new(user) }

  let(:budget_types_group) do
    GroupCatalog.find_or_create_by!(code: 'budget_types') { |g| g.name = 'budget_types' }
  end
  let(:color_catalog) do
    color_group = GroupCatalog.find_or_create_by!(code: 'colors') { |g| g.name = 'colors' }
    Catalog.find_or_create_by!(code: 'purple', group_catalog: color_group) { |c| c.value = 'Purple' }
  end
  let(:icon_catalog) do
    icon_group = GroupCatalog.find_or_create_by!(code: 'budget_icons') { |g| g.name = 'budget_icons' }
    Catalog.find_or_create_by!(code: 'cash', group_catalog: icon_group) { |c| c.value = 'Cash' }
  end

  def budget_type_for(code)
    Catalog.find_or_create_by!(code:, group_catalog: budget_types_group) { |c| c.value = code }
  end

  def make_cash_budget(amount:)
    Budget.create!(
      name: 'Efectivo',
      user:,
      budget_type: budget_type_for('cash'),
      color: color_catalog,
      icon: icon_catalog,
      current_amount: amount,
      personal: true,
      active: true
    )
  end

  describe '#available_balance (private)' do
    context 'con deuda en tarjetas de crédito' do
      before do
        make_cash_budget(amount: 10_000)
        allow(allocator).to receive(:credit_card_debt).and_return(3_000)
      end

      it 'resta la deuda al saldo disponible' do
        expect(allocator.send(:available_balance)).to eq(7_000)
      end
    end

    context 'cuando la deuda supera el saldo total' do
      before do
        make_cash_budget(amount: 5_000)
        allow(allocator).to receive(:credit_card_debt).and_return(10_000)
      end

      it 'retorna cero en lugar de un valor negativo' do
        expect(allocator.send(:available_balance)).to eq(0)
      end
    end

    context 'sin deuda en tarjetas' do
      before { make_cash_budget(amount: 10_000) }

      it 'retorna el saldo total sin descuentos' do
        expect(allocator.send(:available_balance)).to eq(10_000)
      end
    end
  end

  describe '#allocate' do
    context 'sin saldo disponible' do
      it 'retorna hash vacío' do
        create(:saving_goal, user:, target_amount: 10_000)
        expect(allocator.allocate).to eq({})
      end
    end

    context 'sin metas activas' do
      before { make_cash_budget(amount: 50_000) }

      it 'retorna hash vacío' do
        create(:saving_goal, user:, target_amount: 10_000, status: :paused)
        expect(allocator.allocate).to eq({})
      end
    end

    context 'CA1: saldo exacto para completar la primera meta, sobrante va a la segunda' do
      let!(:goal1) { create(:saving_goal, user:, target_amount: 8_000) }
      let!(:goal2) { create(:saving_goal, user:, target_amount: 5_000) }

      before { make_cash_budget(amount: 10_000) }

      it 'asigna 8000 a meta1 y 2000 a meta2' do
        result = allocator.allocate
        expect(result[goal1.id]).to eq(8_000)
        expect(result[goal2.id]).to eq(2_000)
      end
    end

    context 'saldo insuficiente para la primera meta' do
      let!(:goal1) { create(:saving_goal, user:, target_amount: 20_000) }
      let!(:goal2) { create(:saving_goal, user:, target_amount: 10_000) }

      before { make_cash_budget(amount: 5_000) }

      it 'asigna todo el saldo a la meta de mayor prioridad' do
        result = allocator.allocate
        expect(result[goal1.id]).to eq(5_000)
        expect(result[goal2.id]).to be_nil
      end
    end

    context 'saldo que completa múltiples metas' do
      let!(:goal1) { create(:saving_goal, user:, target_amount: 3_000) }
      let!(:goal2) { create(:saving_goal, user:, target_amount: 4_000) }
      let!(:goal3) { create(:saving_goal, user:, target_amount: 5_000) }

      before { make_cash_budget(amount: 15_000) }

      it 'completa las tres metas con saldo suficiente' do
        result = allocator.allocate
        expect(result[goal1.id]).to eq(3_000)
        expect(result[goal2.id]).to eq(4_000)
        expect(result[goal3.id]).to eq(5_000)
      end
    end

    context 'con deuda en tarjetas que reduce el saldo disponible' do
      let!(:goal1) { create(:saving_goal, user:, target_amount: 8_000) }
      let!(:goal2) { create(:saving_goal, user:, target_amount: 5_000) }

      before do
        make_cash_budget(amount: 10_000)
        allow(allocator).to receive(:credit_card_debt).and_return(3_000)
      end

      it 'asigna solo el saldo neto de deuda a metas de mayor prioridad' do
        result = allocator.allocate
        expect(result[goal1.id]).to eq(7_000)
        expect(result[goal2.id]).to be_nil
      end
    end

    context 'metas en pausa no reciben asignación' do
      let!(:goal_active) { create(:saving_goal, user:, target_amount: 10_000) }
      let!(:goal_paused) { create(:saving_goal, user:, target_amount: 10_000, status: :paused) }

      before { make_cash_budget(amount: 15_000) }

      it 'solo asigna a la meta activa' do
        result = allocator.allocate
        expect(result[goal_active.id]).to eq(10_000)
        expect(result[goal_paused.id]).to be_nil
      end
    end

    context 'respeta el orden de prioridad' do
      # Crear en orden inverso al deseado, luego intercambiar para verificar que
      # la asignación respeta priority_order y no el orden de creación.
      let!(:goal_prioridad1) { create(:saving_goal, user:, name: 'Primera', target_amount: 8_000) }
      let!(:goal_prioridad2) { create(:saving_goal, user:, name: 'Segunda', target_amount: 10_000) }

      before { make_cash_budget(amount: 12_000) }

      it 'asigna saldo a la meta con menor priority_order primero' do
        result = allocator.allocate
        expect(result[goal_prioridad1.id]).to eq(8_000)
        expect(result[goal_prioridad2.id]).to eq(4_000)
      end
    end
  end
end
