# frozen_string_literal: true

# Representa un recordatorio de pago de nómina proyectado calculado a partir de EmploymentInformation y PayrollProfile.
class PayrollReminder
  PERIODICITY_LABELS = {
    'daily' => 'Pago diario',
    'weekly' => 'Pago semanal',
    'biweekly' => 'Quincena',
    'monthly' => 'Pago mensual',
    'yearly' => 'Pago anual'
  }.freeze

  attr_reader :date, :net_amount, :calculation_breakdown, :periodicity

  def initialize(date:, net_amount:, calculation_breakdown:, periodicity:)
    @date = date
    @net_amount = net_amount
    @calculation_breakdown = calculation_breakdown
    @periodicity = periodicity
  end

  def periodicity_label
    PERIODICITY_LABELS.fetch(periodicity.to_s, 'Pago de nómina')
  end
end
