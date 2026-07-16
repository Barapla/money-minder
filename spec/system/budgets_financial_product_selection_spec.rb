# frozen_string_literal: true

require 'rails_helper'

# FEAT-026 CA6/CA7: al editar un instrumento existente, el select de institucion debe
# precargar la institucion del producto asociado (CA6) o "Otro" cuando el instrumento
# no tiene financial_product_id (CA7). No se ejercita la actualizacion dinamica del
# select de producto via JS (CA2/CA3) porque este entorno no tiene un driver de
# navegador con JS disponible (ver README de la PR); esa parte se cubre con la spec
# de request al endpoint /financial_products y a change_budget_type.
RSpec.describe 'Edicion de instrumentos financieros (FEAT-026)', type: :system do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }

  before { sign_in user }

  # CreditCard, SavingsFund y TermSaving deben crearse junto con su Budget en una sola
  # llamada: Budget#build_budget_type_if_needed construye un registro anidado en blanco
  # para el tipo elegido, y accepts_nested_attributes_for autosave-valida/persiste ese
  # registro en blanco si no se le pasan atributos reales en la misma llamada.
  def build_budget(budget_type_code, nested_attrs_key: nil, nested_attrs: {})
    Budget.create!(
      {
        name: 'Instrumento de prueba',
        user:,
        budget_type: create(:catalog, code: budget_type_code),
        color:,
        icon:,
        current_amount: 0
      }.merge(nested_attrs_key ? { nested_attrs_key => nested_attrs } : {})
    )
  end

  describe 'CreditCard' do
    it 'CA6: precarga la institucion del producto asociado' do
      budget = build_budget('credit_card', nested_attrs_key: :credit_card_attributes, nested_attrs: {
                              initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5,
                              financial_product_id: 'nu_credit_card'
                            })

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('Nu')
    end

    it 'CA7: precarga Otro cuando no hay financial_product_id' do
      budget = build_budget('credit_card', nested_attrs_key: :credit_card_attributes, nested_attrs: {
                              initial_debt: 0, limit_amount: 20_000, cutting_day: 15, payment_due_days: 5
                            })

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('other')
    end
  end

  describe 'SavingsFund' do
    it 'CA6: precarga la institucion del producto asociado' do
      budget = build_budget('savings_fund', nested_attrs_key: :savings_fund_attributes, nested_attrs: {
                              goal_amount: 10_000, target_date: 1.year.from_now.to_date, monthly_contribution: 500,
                              interest_rate: 5.0, compound_frequency_id: create(:catalog).id,
                              account_type_id: create(:catalog).id, minimum_balance: 0,
                              financial_product_id: 'bbva_savings_fund'
                            })

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('BBVA')
    end

    it 'CA7: precarga Otro cuando no hay financial_product_id' do
      budget = build_budget('savings_fund', nested_attrs_key: :savings_fund_attributes, nested_attrs: {
                              goal_amount: 10_000, target_date: 1.year.from_now.to_date, monthly_contribution: 500,
                              interest_rate: 5.0, compound_frequency_id: create(:catalog).id,
                              account_type_id: create(:catalog).id, minimum_balance: 0
                            })

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('other')
    end
  end

  describe 'DebitCard (Budget sin modelo propio)' do
    it 'CA6: precarga la institucion del producto asociado' do
      budget = build_budget('debit_card')
      budget.update!(financial_product_id: 'klar_debit_card')

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('Klar')
    end

    it 'CA7: precarga Otro cuando no hay financial_product_id' do
      budget = build_budget('debit_card')

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('other')
    end
  end

  describe 'TermSaving' do
    # TermSaving tiene validaciones de presencia (a diferencia de CreditCard/SavingsFund),
    # asi que debe crearse junto con su Budget en una sola llamada: el registro en blanco
    # que Budget#build_budget_type_if_needed construye para un Budget nuevo no pasaria
    # sus propias validaciones si se guardara solo.
    def build_term_saving_budget(attrs)
      base_attrs = { id: nil, term_days: 90, rate_locked: 0.12, started_at: Date.current, principal_amount: 10_000 }
      Budget.create!(
        name: 'Instrumento de prueba', user:, budget_type: create(:catalog, code: 'term_saving'),
        color:, icon:, current_amount: 0, term_savings_attributes: base_attrs.merge(attrs)
      )
    end

    it 'CA6: precarga la institucion del producto asociado' do
      budget = build_term_saving_budget(financial_product_id: 'nu_frozen_savings90')

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('Nu')
    end

    it 'CA7: precarga Otro cuando no hay financial_product_id' do
      budget = build_term_saving_budget(name: 'Manual')

      visit edit_budget_path(budget)

      expect(find_field('Institución financiera').value).to eq('other')
    end
  end
end
