# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SavingGoalServices::ProgressCalculator, type: :service do
  let(:user) { create(:user) }
  let(:calculator) { described_class.new(user) }

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

  def make_budget(type_code:, amount:, personal: false)
    Budget.create!(
      name: "Budget #{type_code}",
      user:,
      budget_type: budget_type_for(type_code),
      color: color_catalog,
      icon: icon_catalog,
      current_amount: amount,
      personal:,
      active: true
    )
  end

  describe '#calculate_for' do
    let(:goal) { build(:saving_goal, user:, target_amount: 80_000) }

    context 'sin saldos' do
      it 'retorna 0% de progreso' do
        result = calculator.calculate_for(goal)
        expect(result[:available_money]).to eq(0)
        expect(result[:progress_percentage]).to eq(0)
        expect(result[:is_achieved]).to be false
      end
    end

    context 'con efectivo y debito iguales al objetivo (CA3 simplificado)' do
      before do
        make_budget(type_code: 'cash', amount: 50_000, personal: true)
        make_budget(type_code: 'debit_card', amount: 30_000)
      end

      it 'calcula dinero disponible sumando efectivo y debito' do
        result = calculator.calculate_for(goal)
        expect(result[:available_money]).to eq(80_000)
        expect(result[:progress_percentage]).to eq(100.0)
      end
    end

    context 'con saldo mayor al objetivo' do
      before do
        make_budget(type_code: 'cash', amount: 100_000, personal: true)
      end

      it 'retorna progreso mayor a 100% y marca como alcanzada' do
        result = calculator.calculate_for(goal)
        expect(result[:progress_percentage]).to eq(125.0)
        expect(result[:is_achieved]).to be true
      end
    end

    context 'con deadline presente' do
      let(:goal_with_deadline) { build(:saving_goal, user:, target_amount: 10_000, deadline: Date.today + 30) }

      it 'calcula los dias restantes' do
        result = calculator.calculate_for(goal_with_deadline)
        expect(result[:days_remaining]).to eq(30)
      end
    end

    context 'sin deadline' do
      let(:goal_no_deadline) { build(:saving_goal, user:, target_amount: 10_000, deadline: nil) }

      it 'retorna nil en days_remaining' do
        result = calculator.calculate_for(goal_no_deadline)
        expect(result[:days_remaining]).to be_nil
      end
    end

    context 'memoizacion de available_money' do
      it 'calcula cash_balance una sola vez para multiples goals' do
        goal2 = build(:saving_goal, user:, target_amount: 20_000)

        expect(calculator).to receive(:cash_balance).once.and_call_original
        calculator.calculate_for(goal)
        calculator.calculate_for(goal2)
      end
    end
  end
end
