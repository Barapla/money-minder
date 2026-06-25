# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:own_budget) { create(:budget, user:) }
  let(:other_budget) { create(:budget, user: other_user) }

  describe 'validaciones de pertenencia de budget' do
    context 'cuando el budget pertenece al mismo usuario' do
      it 'es valida' do
        transaction = build(:transaction, user:, budget: own_budget)
        expect(transaction).to be_valid
      end
    end

    context 'cuando el budget pertenece a otro usuario' do
      it 'es invalida' do
        transaction = build(:transaction, user:, budget: other_budget)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:budget_id]).to include('debe pertenecer al mismo usuario')
      end
    end

    context 'al actualizar cambiando a un budget ajeno' do
      it 'rechaza el cambio' do
        transaction = create(:transaction, user:, budget: own_budget)
        transaction.budget = other_budget
        expect(transaction).not_to be_valid
        expect(transaction.errors[:budget_id]).to include('debe pertenecer al mismo usuario')
      end
    end
  end
end
