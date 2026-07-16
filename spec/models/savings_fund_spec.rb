# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SavingsFund, type: :model do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:compound_frequency) { create(:catalog) }
  let(:account_type) { create(:catalog) }
  let(:invalid_product_message) { 'no corresponde a ningun producto del catalogo financiero' }
  let(:budget) do
    Budget.create!(
      name: 'Ahorro de Prueba',
      user:,
      budget_type: create(:catalog),
      color: create(:catalog),
      icon: create(:catalog),
      current_amount: 0
    )
  end

  def build_savings_fund(attrs = {})
    SavingsFund.new(default_savings_fund_attrs.merge(attrs))
  end

  def default_savings_fund_attrs
    {
      budget:,
      goal_amount: 10_000,
      target_date: 1.year.from_now.to_date,
      monthly_contribution: 500,
      interest_rate: 5.0,
      compound_frequency_id: compound_frequency.id,
      account_type_id: account_type.id
    }
  end

  describe 'asociacion a un producto del catalogo (CA5)' do
    it 'autogenera el nombre del budget asociado a partir del producto' do
      fund = build_savings_fund(financial_product_id: 'bbva_savings_fund')

      expect(fund).to be_valid
      expect(budget.reload.name).to eq('Cuenta Ahorro Digital de Bryan')
    end
  end

  describe 'financial_product_id invalido' do
    it 'falla la validacion con un mensaje claro' do
      fund = build_savings_fund(financial_product_id: 'no_existe')

      expect(fund).to be_invalid
      expect(fund.errors[:financial_product_id]).to include(invalid_product_message)
    end
  end

  describe 'sin financial_product_id' do
    it 'es valido y no toca el nombre del budget' do
      fund = build_savings_fund

      expect(fund).to be_valid
      expect(budget.reload.name).to eq('Ahorro de Prueba')
    end
  end
end
