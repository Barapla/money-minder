# frozen_string_literal: true

require 'rails_helper'

# FEAT-027: flujo completo del wizard de creacion. Cada paso es una navegacion real por
# enlaces (progressive enhancement de Turbo Frames), por lo que corre completo sobre
# rack_test sin necesidad de un driver con JS (ver memoria de entorno del proyecto).
RSpec.describe 'Wizard de creacion de presupuestos (FEAT-027)', type: :system do
  let(:user) { create(:user, first_name: 'Bryan') }
  let(:budget_types_group) { create(:group_catalog, code: 'budget_types') }

  def create_budget_type(code, value)
    create(:catalog, code:, value:, group_catalog: budget_types_group)
  end

  before do
    create(:catalog, group_catalog: create(:group_catalog, code: 'budget_icons'))
    create(:catalog, group_catalog: create(:group_catalog, code: 'colors'))
    sign_in user
  end

  it 'CA1-CA10: completa el flujo de creacion paso a paso con producto del catalogo' do
    create_budget_type('credit_card', 'Tarjeta de crédito')

    visit new_budget_path

    expect(page).to have_selector('[data-testid="wizard-progress-indicator"]')
    expect(page).to have_content('Tarjeta de crédito')

    click_link 'Tarjeta de crédito'
    expect(page).to have_content('Elige la institución financiera')

    click_link 'Nu'
    expect(page).to have_content('Elige el producto de Nu')
    expect(page).to have_content('Nu Credito')

    click_link 'Nu Credito'
    expect(page).to have_content('Completa los detalles')
    expect(find_field('Institución financiera').value).to eq('Nu')

    fill_in 'Nombre del presupuesto', with: 'sera reemplazado'
    fill_in 'Presupuesto inicial de deuda', with: 0
    fill_in 'Presupuesto límite', with: 20_000
    fill_in 'Día de corte', with: 15
    fill_in 'Días para el pago', with: 5

    expect { click_button 'Crear presupuesto' }.to change(Budget, :count).by(1)

    budget = Budget.last
    expect(budget.credit_card.financial_product_id).to eq('nu_credit_card')
    expect(budget.name).to eq('Cuenta Nu Credito de Bryan')
  end

  it 'CA8: "Atrás" regresa al paso anterior manteniendo el tipo seleccionado' do
    create_budget_type('credit_card', 'Tarjeta de crédito')

    visit new_budget_path
    click_link 'Tarjeta de crédito'
    click_link 'Atrás'

    expect(page).to have_content('¿Qué tipo de presupuesto quieres crear?')
  end

  it 'permite crear sin producto del catalogo mediante la opcion "Otro"' do
    create_budget_type('credit_card', 'Tarjeta de crédito')

    visit new_budget_path
    click_link 'Tarjeta de crédito'
    click_link 'Otro'

    expect(page).to have_content('Completa los detalles')

    fill_in 'Nombre del presupuesto', with: 'Mi tarjeta manual'
    fill_in 'Presupuesto inicial de deuda', with: 0
    fill_in 'Presupuesto límite', with: 20_000
    fill_in 'Día de corte', with: 15
    fill_in 'Días para el pago', with: 5

    expect { click_button 'Crear presupuesto' }.to change(Budget, :count).by(1)

    budget = Budget.last
    expect(budget.credit_card.financial_product_id).to be_blank
    expect(budget.name).to eq('Mi tarjeta manual')
  end

  it 'CA2: un tipo sin productos en el catalogo (cash) salta directo al paso 4' do
    create_budget_type('cash', 'Efectivo')

    visit new_budget_path
    click_link 'Efectivo'

    expect(page).to have_content('Completa los detalles')
  end
end
