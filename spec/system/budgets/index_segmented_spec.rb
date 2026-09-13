# frozen_string_literal: true

require 'rails_helper'

# FEAT-032: verifica el renderizado server-side de las secciones del index segmentado.
# No hay chromedriver en este sandbox (ver spec/rails_helper.rb), asi que corre con
# rack_test: cubre HTML estatico, no comportamiento JS.
RSpec.describe 'Index segmentado de presupuestos (FEAT-032)', type: :system do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }
  let(:color) { create(:catalog) }
  let(:icon) { create(:catalog) }

  def create_budget_type(code)
    create(:catalog, code:, group_catalog: budget_types_group)
  end

  # savings_funds tiene compound_frequency_id/account_type_id NOT NULL en DB.
  def create_budget(code, name:)
    nested_attrs = if code == 'savings_fund'
                     { savings_fund_attributes: { compound_frequency_id: create(:catalog).id,
                                                  account_type_id: create(:catalog).id } }
                   else
                     {}
                   end
    Budget.create!({ name:, user:, budget_type: create_budget_type(code), color:, icon:,
                     current_amount: 0 }.merge(nested_attrs))
  end

  before { sign_in user }

  it 'CA2, CA3, CA5, CA6: muestra secciones de debito y ahorro con contador, sin la de credito' do
    create_budget('debit_card', name: 'Debito Klar')
    create_budget('savings_fund', name: 'Ahorro BBVA')

    visit budgets_path

    expect(page).to have_content('Tarjetas de Débito')
    expect(page).to have_content('Fondos de Ahorro')
    expect(page).to have_content('Debito Klar')
    expect(page).to have_content('Ahorro BBVA')
    expect(page).to have_content('1 presupuesto', count: 2)
    expect(page).not_to have_content('Tarjetas de Crédito')
  end

  it 'CA7: muestra el estado vacio cuando el usuario no tiene presupuestos' do
    visit budgets_path

    expect(page).to have_content('No hay presupuestos')
    expect(page).to have_link('Crear Presupuesto', href: new_budget_path)
  end
end
