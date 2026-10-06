# frozen_string_literal: true

# FEAT-029: recordatorios de cobros unicos y recurrentes.
# reminder_type distingue dinero que sale (payment) de dinero que entra (income).
# due_date es la fecha del recordatorio cuando no tiene Recurrence asociada (one-time).
class AddReminderTypeAndDueDateToObligatoryPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :obligatory_payments, :reminder_type, :string, default: 'payment', null: false
    add_column :obligatory_payments, :due_date, :date

    add_index :obligatory_payments, :reminder_type
    add_index :obligatory_payments, :due_date
  end
end
