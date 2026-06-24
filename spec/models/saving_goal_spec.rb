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
  end
end
