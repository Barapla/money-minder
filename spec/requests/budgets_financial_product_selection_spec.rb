# frozen_string_literal: true

require 'rails_helper'

# FEAT-026: los 4 formularios de instrumentos financieros ahora consultan el Registry
# para institucion/producto. Estos specs cubren CA4/CA5/CA8: persistencia correcta con
# producto del catalogo y con la opcion "Otro" (financial_product_id nil), para los
# cuatro tipos de instrumento (CreditCard, DebitCard, SavingsFund, TermSaving).
RSpec.describe '/budgets financial_product_id anidado (FEAT-026)', type: :request do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }

  before { sign_in user }

  def base_params(budget_type_code)
    {
      name: 'sera reemplazado o mantenido',
      budget_type_id: create(:catalog, code: budget_type_code).id,
      color_id: color.id,
      icon_id: icon.id,
      current_amount: 0
    }
  end

  describe 'POST /budgets/change_budget_type (CA1/CA8: select de institucion por tipo)' do
    %w[credit_card debit_card savings_fund term_saving].each do |code|
      it "incluye el select de institucion con la opcion Otro para #{code}" do
        budget_type = create(:catalog, code:)

        post change_budget_type_budgets_path,
             params: { budget: { budget_type_id: budget_type.id } },
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response.body).to include('Selecciona una institución')
        expect(response.body).to include('>Otro<')
      end
    end
  end

  describe 'CreditCard' do
    it 'CA4: crea con producto del catalogo y autogenera el nombre' do
      params = base_params('credit_card').merge(
        credit_card_attributes: {
          initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5,
          financial_product_id: 'nu_credit_card'
        }
      )

      post budgets_path, params: { budget: params }

      budget = Budget.last
      expect(budget.credit_card.financial_product_id).to eq('nu_credit_card')
      expect(budget.name).to eq('Cuenta Nu Credito de Bryan')
    end

    it 'CA5: crea con Otro y mantiene el nombre manual sin financial_product_id' do
      params = base_params('credit_card').merge(
        name: 'Mi tarjeta manual',
        credit_card_attributes: { initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5 }
      )

      post budgets_path, params: { budget: params }

      budget = Budget.last
      expect(budget.credit_card.financial_product_id).to be_nil
      expect(budget.name).to eq('Mi tarjeta manual')
    end
  end

  describe 'DebitCard (Budget sin modelo propio)' do
    it 'CA4: crea con producto del catalogo y autogenera el nombre' do
      params = base_params('debit_card').merge(financial_product_id: 'klar_debit_card')

      post budgets_path, params: { budget: params }

      budget = Budget.last
      expect(budget.financial_product_id).to eq('klar_debit_card')
      expect(budget.name).to eq('Cuenta Klar Debito de Bryan')
    end

    it 'CA5: crea con Otro y mantiene el nombre manual' do
      params = base_params('debit_card').merge(name: 'Mi debito manual')

      post budgets_path, params: { budget: params }

      budget = Budget.last
      expect(budget.financial_product_id).to be_nil
      expect(budget.name).to eq('Mi debito manual')
    end
  end

  describe 'SavingsFund' do
    it 'CA4: crea con producto del catalogo y autogenera el nombre' do
      params = base_params('savings_fund').merge(
        savings_fund_attributes: {
          goal_amount: 10_000, target_date: 1.year.from_now.to_date, monthly_contribution: 500,
          interest_rate: 5.0, compound_frequency_id: create(:catalog).id, account_type_id: create(:catalog).id,
          minimum_balance: 0, financial_product_id: 'bbva_savings_fund'
        }
      )

      post budgets_path, params: { budget: params }

      budget = Budget.last
      expect(budget.savings_fund.financial_product_id).to eq('bbva_savings_fund')
      expect(budget.name).to eq('Cuenta Ahorro Digital de Bryan')
    end

    it 'CA5: crea con Otro y mantiene el nombre manual' do
      params = base_params('savings_fund').merge(
        name: 'Mi fondo manual',
        savings_fund_attributes: {
          goal_amount: 10_000, target_date: 1.year.from_now.to_date, monthly_contribution: 500,
          interest_rate: 5.0, compound_frequency_id: create(:catalog).id, account_type_id: create(:catalog).id,
          minimum_balance: 0
        }
      )

      post budgets_path, params: { budget: params }

      budget = Budget.last
      expect(budget.savings_fund.financial_product_id).to be_nil
      expect(budget.name).to eq('Mi fondo manual')
    end
  end

  describe 'TermSaving' do
    it 'CA4: crea con producto del catalogo y autogenera el nombre con prefijo Ahorro' do
      params = base_params('term_saving').merge(
        term_savings_attributes: {
          id: '', term_days: 90, rate_locked: 0.12, started_at: Date.current, principal_amount: 10_000,
          financial_product_id: 'nu_frozen_savings90'
        }
      )

      post budgets_path, params: { budget: params }

      term_saving = Budget.last.term_savings.first
      expect(term_saving.financial_product_id).to eq('nu_frozen_savings90')
      expect(term_saving.name).to eq('Ahorro Congelado 90 dias de Bryan')
    end

    it 'CA5: crea con Otro y usa el nombre manual del term_saving' do
      params = base_params('term_saving').merge(
        term_savings_attributes: {
          id: '', name: 'Mi plazo fijo manual', term_days: 90, rate_locked: 0.12,
          started_at: Date.current, principal_amount: 10_000
        }
      )

      post budgets_path, params: { budget: params }

      term_saving = Budget.last.term_savings.first
      expect(term_saving.financial_product_id).to be_nil
      expect(term_saving.name).to eq('Mi plazo fijo manual')
    end
  end
end
