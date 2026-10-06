# frozen_string_literal: true

# Serializa un recordatorio (pago obligatorio o cobro) para la API movil.
class ObligatoryPaymentSerializer
  def initialize(payment)
    @payment = payment
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength -- lectura plana de campos, sin logica
  def as_json(*)
    {
      id: payment.id,
      name: payment.name,
      amount: payment.amount.to_f,
      reminder_type: payment.reminder_type,
      category_name: payment.category&.name,
      icon: payment.icon&.value,
      color: payment.color&.value,
      due_date: payment.one_time? ? payment.due_date : nil,
      next_due_date: payment.one_time? ? payment.due_date : payment.next_due_date,
      recurrence: recurrence_json
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  attr_reader :payment

  def recurrence_json
    return nil if payment.one_time?

    rec = payment.recurrence
    { frequency: rec.frequency_type&.code, frequency_value: rec.frequency_value,
      start_date: rec.start_date, end_date: rec.end_date }
  end
end
