# frozen_string_literal: true

require 'rails_helper'

# FEAT-029: recordatorios de cobros unicos y recurrentes.
# Este entorno no tiene driver de navegador con JS (ver README de la PR), asi que el
# toggle Stimulus de los campos de recurrencia (previews--obligatory-payments#toggleRecurrence)
# no se ejercita aqui: los campos siguen presentes en el DOM con rack_test y son
# rellenables aunque esten ocultos visualmente via CSS.
RSpec.describe 'Recordatorios de pagos y cobros (FEAT-029)', type: :system do
  let(:user) { create(:user) }
  let(:parent_category) { create(:category) }
  let(:category) { create(:category, parent_category: parent_category) }
  let(:colors_group) { create(:group_catalog, code: 'colors') }
  let(:icons_group) { create(:group_catalog, code: 'transaction_icons') }
  let(:frequency_group) { create(:group_catalog, code: 'frequency_types') }
  let(:recurrenceable_types_group) { create(:group_catalog, code: 'recurrenceable_types') }

  before do
    create(:catalog, group_catalog: colors_group, value: 'purple', code: 'purple')
    create(:catalog, group_catalog: icons_group, value: '💳', code: 'card')
    create(:catalog, group_catalog: frequency_group, value: 'Mensual', code: 'monthly')
    create(:catalog, group_catalog: recurrenceable_types_group, value: 'Pago Obligatorio', code: 'obligatory_payment')
    category
    sign_in user
  end

  it 'CA1 y CA2: crea un recordatorio de cobro unico sin regla de recurrencia' do
    visit new_obligatory_payment_path

    fill_in 'Nombre del pago', with: 'Reembolso de cliente'
    fill_in 'Monto', with: '500'
    select category.name, from: 'Categoría'
    choose 'obligatory_payment_reminder_type_income'
    check 'obligatory_payment_one_time'
    fill_in 'Fecha del recordatorio', with: Date.tomorrow.strftime('%Y-%m-%d')

    click_button 'Guardar Pago Obligatorio'

    expect(page).to have_current_path(obligatory_payments_path)

    reminder = ObligatoryPayment.find_by!(name: 'Reembolso de cliente')
    expect(reminder).to be_income
    expect(reminder).to be_one_time
    expect(reminder.due_date).to eq(Date.tomorrow)
    expect(reminder.recurrence).to be_nil
  end

  it 'CA2: crea un recordatorio de pago recurrente sin due_date' do
    visit new_obligatory_payment_path

    fill_in 'Nombre del pago', with: 'Renta mensual'
    fill_in 'Monto', with: '3000'
    select category.name, from: 'Categoría'
    choose 'obligatory_payment_reminder_type_payment'
    fill_in 'obligatory_payment[recurrence_attributes][start_date]', with: Date.current.strftime('%Y-%m-%d')
    select 'Mensual', from: 'obligatory_payment[recurrence_attributes][frequency_type_id]'
    fill_in 'obligatory_payment[recurrence_attributes][frequency_value]', with: '1'

    click_button 'Guardar Pago Obligatorio'

    expect(page).to have_current_path(obligatory_payments_path)

    reminder = ObligatoryPayment.find_by!(name: 'Renta mensual')
    expect(reminder).to be_payment
    expect(reminder).to be_recurring
    expect(reminder.due_date).to be_nil
  end

  it 'CA4: filtra la lista de recordatorios por tipo' do
    create(:obligatory_payment, user:, category:, color: create(:catalog), icon: create(:catalog),
                                name: 'Pago de luz', reminder_type: 'payment', due_date: Date.tomorrow)
    create(:obligatory_payment, user:, category:, color: create(:catalog), icon: create(:catalog),
                                name: 'Cobro de renta', reminder_type: 'income', due_date: Date.tomorrow)

    visit obligatory_payments_path(reminder_type: 'income')

    expect(page).to have_content('Cobro de renta')
    expect(page).not_to have_content('Pago de luz')
  end

  it 'CA3: distingue visualmente pagos y cobros en el calendario del dia' do
    create(:obligatory_payment, user:, category:, color: create(:catalog), icon: create(:catalog),
                                name: 'Pago de luz', reminder_type: 'payment', due_date: Date.current)
    create(:obligatory_payment, user:, category:, color: create(:catalog), icon: create(:catalog),
                                name: 'Cobro de renta', reminder_type: 'income', due_date: Date.current)

    visit day_details_obligatory_payments_calendar_index_path(date: Date.current.strftime('%Y-%m-%d'))

    expect(page).to have_css('.reminder-payment', text: 'Pago de luz')
    expect(page).to have_css('.reminder-income', text: 'Cobro de renta')
  end

  it 'CA5: permite marcar un recordatorio unico como completado' do
    reminder = create(:obligatory_payment, user:, category:, color: create(:catalog), icon: create(:catalog),
                                           name: 'Cobro de cliente', reminder_type: 'income', due_date: Date.tomorrow)

    visit obligatory_payments_path

    click_button 'Marcar como completado'

    expect(reminder.reload.done).to be(true)
    expect(page).to have_button('Completado ✓ (marcar como pendiente)')
  end
end
