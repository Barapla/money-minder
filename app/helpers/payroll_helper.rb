# frozen_string_literal: true

# Helpers para formatear montos de nómina en vistas.
module PayrollHelper
  def format_currency(amount)
    return '$0.00' if amount.nil?

    "$#{format('%.2f', amount)}"
  end
end
