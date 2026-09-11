# frozen_string_literal: true

module ChatbotServices
  # Total de recordatorios (ObligatoryPayment) programados en un rango de fechas,
  # separados por reminder_type: income (lo que va a llegar) y payment (lo que
  # deberia gastar idealmente). Contexto adicional para el advisor de Claude,
  # independiente de NetFlowCalculator (que usa promedios por frecuencia, no
  # fechas reales dentro del mes).
  class ScheduledRemindersSummary
    def initialize(user, from_date: Date.current.beginning_of_month, to_date: Date.current.end_of_month)
      @user = user
      @from_date = from_date
      @to_date = to_date
    end

    def scheduled_income_total
      total_for('income')
    end

    def scheduled_payment_total
      total_for('payment')
    end

    private

    attr_reader :user, :from_date, :to_date

    def total_for(type)
      user.obligatory_payments.by_type(type).includes(:recurrence).sum { |payment| occurrences_amount(payment) }
    end

    def occurrences_amount(payment)
      amount = payment.amount.to_f

      if payment.one_time?
        payment.due_date&.between?(from_date, to_date) ? amount : 0.0
      else
        payment.recurrence.occurrences_in_range(from_date, to_date).size * amount
      end
    end
  end
end
