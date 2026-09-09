# frozen_string_literal: true

require 'rails_helper'

# FEAT-029 (segunda ronda de review): la baja de la recurrencia al pasar a "unico"
# debe ocurrir dentro de la misma transaccion de update, no antes de validar, y no
# debe dispararse cuando el usuario mantiene la recurrencia existente.
RSpec.describe 'PATCH /obligatory_payments/:id', type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  before { sign_in user }

  def create_recurring_payment
    payment = build(:obligatory_payment, user:, category:, due_date: nil)
    payment.build_recurrence(
      frequency_type: create(:catalog),
      recurrenceable_type_catalog: create(:catalog),
      frequency_value: 1,
      start_date: Date.current
    )
    payment.save!
    payment
  end

  it 'al marcar one_time destruye la recurrencia existente y exige due_date' do
    payment = create_recurring_payment

    patch obligatory_payment_path(payment),
          params: { obligatory_payment: { one_time: '1', due_date: Date.tomorrow.to_s } }

    expect(payment.reload).to be_one_time
    expect(payment.recurrence).to be_nil
  end

  it 'no destruye la recurrencia cuando el usuario la mantiene (one_time false)' do
    payment = create_recurring_payment
    recurrence_id = payment.recurrence.id

    patch obligatory_payment_path(payment), params: { obligatory_payment: { one_time: '0', name: payment.name } }

    expect(Recurrence.exists?(recurrence_id)).to be(true)
    expect(payment.reload).to be_recurring
  end

  it 'GET /edit de un recordatorio unico no lo muestra como recurrente' do
    payment = create(:obligatory_payment, user:, category:, due_date: Date.tomorrow)

    get edit_obligatory_payment_path(payment)

    checkbox = Nokogiri::HTML(response.body).at_css('#obligatory_payment_one_time')
    expect(checkbox[:checked]).to eq('checked')
  end
end
