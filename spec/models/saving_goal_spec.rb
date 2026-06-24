# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SavingGoal, type: :model do
  subject(:saving_goal) { build(:saving_goal) }

  describe 'asociaciones' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validaciones' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:target_amount) }
    it { is_expected.to validate_numericality_of(:target_amount).is_greater_than(0) }
    describe 'unicidad de priority_order por usuario' do
      let(:user) { create(:user) }

      it 'no permite dos metas con el mismo priority_order para el mismo usuario' do
        create(:saving_goal, user:, priority_order: 1)
        duplicate = build(:saving_goal, user:, priority_order: 1)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:priority_order]).to be_present
      end

      it 'permite el mismo priority_order para usuarios distintos' do
        other_user = create(:user)
        create(:saving_goal, user:, priority_order: 1)
        goal = build(:saving_goal, user: other_user, priority_order: 1)
        expect(goal).to be_valid
      end
    end

    context 'deadline en el pasado al crear' do
      it 'es invalido' do
        goal = build(:saving_goal, deadline: Date.yesterday)
        expect(goal).not_to be_valid
        expect(goal.errors[:deadline]).to be_present
      end
    end

    context 'deadline en el futuro' do
      it 'es valido' do
        goal = build(:saving_goal, deadline: Date.tomorrow)
        expect(goal).to be_valid
      end
    end

    context 'sin deadline' do
      it 'es valido' do
        goal = build(:saving_goal, deadline: nil)
        expect(goal).to be_valid
      end
    end

    context 'deadline pasado en actualizacion' do
      it 'no valida la fecha en update' do
        goal = create(:saving_goal, deadline: Date.tomorrow)
        goal.deadline = Date.yesterday
        expect(goal).to be_valid
      end
    end
  end

  describe 'enum status' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, paused: 1, achieved: 2, cancelled: 3) }
  end

  describe 'callbacks de priority_order' do
    let(:user) { create(:user) }

    describe '#assign_last_priority (before_validation on create)' do
      it 'asigna priority_order = 1 a la primera meta' do
        goal = create(:saving_goal, user:)
        expect(goal.priority_order).to eq(1)
      end

      it 'asigna la última prioridad (max + 1) a metas posteriores' do
        create(:saving_goal, user:)
        create(:saving_goal, user:)
        third = create(:saving_goal, user:)
        expect(third.priority_order).to eq(3)
      end

      it 'no sobreescribe un priority_order asignado explícitamente' do
        goal = create(:saving_goal, user:, priority_order: 5)
        expect(goal.priority_order).to eq(5)
      end
    end

    describe '#renumber_priorities (after_destroy)' do
      it 'renumera sin gaps al eliminar una meta intermedia (CA7)' do
        goal1 = create(:saving_goal, user:, name: 'Meta 1')
        goal2 = create(:saving_goal, user:, name: 'Meta 2')
        goal3 = create(:saving_goal, user:, name: 'Meta 3')

        goal2.destroy

        expect(goal1.reload.priority_order).to eq(1)
        expect(goal3.reload.priority_order).to eq(2)
      end

      it 'no deja gaps al eliminar la primera meta' do
        goal1 = create(:saving_goal, user:, name: 'Primera')
        goal2 = create(:saving_goal, user:, name: 'Segunda')
        goal3 = create(:saving_goal, user:, name: 'Tercera')

        goal1.destroy

        expect(goal2.reload.priority_order).to eq(1)
        expect(goal3.reload.priority_order).to eq(2)
      end
    end
  end

  describe 'scopes' do
    describe '.recent_first' do
      it 'ordena por created_at desc' do
        user = create(:user)
        old_goal = create(:saving_goal, user:, created_at: 2.days.ago)
        new_goal = create(:saving_goal, user:, created_at: 1.day.ago)

        expect(user.saving_goals.recent_first.first).to eq(new_goal)
        expect(user.saving_goals.recent_first.last).to eq(old_goal)
      end
    end

    describe '.by_status' do
      it 'filtra por estado' do
        user = create(:user)
        active_goal = create(:saving_goal, user:, status: :active)
        create(:saving_goal, user:, status: :paused)

        expect(user.saving_goals.by_status(:active)).to include(active_goal)
        expect(user.saving_goals.by_status(:active).count).to eq(1)
      end
    end

    describe '.by_priority' do
      it 'ordena por priority_order ascendente' do
        user = create(:user)
        goal1 = create(:saving_goal, user:)
        goal2 = create(:saving_goal, user:)
        goal3 = create(:saving_goal, user:)

        expect(user.saving_goals.by_priority.to_a).to eq([goal1, goal2, goal3])
      end
    end
  end
end
