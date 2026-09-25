# frozen_string_literal: true

module DebtServices
  # Crea (o actualiza) el ObligatoryPayment que le corresponde a una deuda a
  # plazos, con su Recurrence. La deuda es la dueña: al borrarla se lo lleva.
  #
  # Reusa el recordatorio que ya existia en vez de inventar un calendario propio,
  # asi el dia sigue saliendo una sola vez en el calendario y en el dashboard.
  class ReminderBuilder
    FREQUENCIES = %w[daily weekly monthly yearly].freeze

    def initialize(debt, frequency: 'weekly', frequency_value: 1, day_of_week: nil, day_of_month: nil)
      @debt = debt
      @frequency = FREQUENCIES.include?(frequency.to_s) ? frequency.to_s : 'weekly'
      @frequency_value = frequency_value.to_i.positive? ? frequency_value.to_i : 1
      @day_of_week = day_of_week
      @day_of_month = day_of_month
    end

    # Sin plan de pagos no hay nada que recordar: una deuda a pagar "cuando se
    # pueda" solo lleva saldo.
    def call
      return nil unless debt.installments?

      debt.obligatory_payment ? update_reminder : create_reminder
    end

    private

    attr_reader :debt, :frequency, :frequency_value, :day_of_week, :day_of_month

    def create_reminder
      reminder = ObligatoryPayment.create!(reminder_attributes.merge(recurrence_attributes: recurrence_params))
      debt.update!(obligatory_payment: reminder)
      reminder
    end

    def update_reminder
      debt.obligatory_payment.tap do |reminder|
        reminder.update!(reminder_attributes)
        reminder.recurrence&.update!(recurrence_params.except(:recurrenceable_type_id))
      end
    end

    def reminder_attributes
      { user: debt.user, name: debt.name, amount: debt.installment_amount,
        description: debt.notes, reminder_type: debt.reminder_type }
        .merge(presentation_attributes)
    end

    # ObligatoryPayment exige los tres; si la deuda no los trae, se toman del
    # catalogo para no bloquear el alta por un detalle cosmetico.
    def presentation_attributes
      {
        category: debt.category || fallback_category,
        color: debt.color || fallback_catalog('colors', 'purple'),
        icon: debt.icon || fallback_catalog('transaction_icons', 'personal_loans')
      }
    end

    def recurrence_params
      {
        recurrenceable_type_id: recurrenceable_type.id,
        frequency_type_id: frequency_catalog.id,
        frequency_value:,
        day_of_week:,
        day_of_month:,
        start_date: debt.started_on,
        end_date: debt.expected_end_on
      }
    end

    def recurrenceable_type
      Catalog.by_group_and_code('recurrenceable_types', 'obligatory_payment')
    end

    def frequency_catalog
      Catalog.by_group_and_code('frequency_types', frequency)
    end

    def fallback_category
      Category.find_by(name: 'Préstamos personales') || Category.first
    end

    def fallback_catalog(group, code)
      Catalog.by_group(group).find_by(code:) || Catalog.by_group(group).first
    end
  end
end
