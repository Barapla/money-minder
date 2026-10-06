# frozen_string_literal: true

# Una deuda puede ser solo un apunte de "fulano me debe", sin fecha de inicio ni
# plan de pagos. La fecha solo hace falta cuando hay cuotas, porque de ahi
# arranca la recurrencia del recordatorio.
class AllowDebtsWithoutDates < ActiveRecord::Migration[7.2]
  def change
    change_column_null :debts, :started_on, true
  end
end
