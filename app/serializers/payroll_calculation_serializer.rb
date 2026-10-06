# frozen_string_literal: true

# Serializa resultados de cálculos de nómina formateando BigDecimal a string.
class PayrollCalculationSerializer
  def initialize(data)
    @data = data
  end

  def as_json(*)
    @data.transform_values { |v| v.is_a?(BigDecimal) ? v.to_s('F') : v }
  end

  private

  attr_reader :data
end
