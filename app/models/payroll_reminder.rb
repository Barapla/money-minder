# frozen_string_literal: true

# Representa un recordatorio de pago de nómina proyectado calculado a partir de EmploymentInformation y PayrollProfile.
class PayrollReminder
  PAYMENT_FREQUENCY_LABELS = {
    'weekly' => 'Pago semanal',
    'biweekly' => 'Quincena',
    'monthly' => 'Pago mensual'
  }.freeze

  NEXT_PERIOD_LABELS = {
    'weekly' => 'Próximo pago semanal',
    'biweekly' => 'Próxima quincena',
    'monthly' => 'Próximo pago mensual'
  }.freeze

  attr_reader :date, :net_amount, :calculation_breakdown, :payment_frequency

  def initialize(date:, net_amount:, calculation_breakdown:, payment_frequency:)
    @date = date
    @net_amount = net_amount
    @calculation_breakdown = calculation_breakdown
    @payment_frequency = payment_frequency
  end

  def periodicity_label
    PAYMENT_FREQUENCY_LABELS.fetch(payment_frequency.to_s, 'Pago de nómina')
  end

  def next_period_label
    NEXT_PERIOD_LABELS.fetch(payment_frequency.to_s, 'Próxima nómina')
  end
end
