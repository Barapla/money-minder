# frozen_string_literal: true

# Movimientos y recordatorios de un mes para el calendario de la app movil.
# Los recordatorios recurrentes se expanden a cada fecha en que ocurren.
class CalendarMonthSerializer
  def initialize(user, month:)
    @user = user
    @range = month.beginning_of_month..month.end_of_month
  end

  def as_json(*)
    {
      month: range.begin.strftime('%Y-%m'),
      transactions: transactions.map { |t| TransactionSerializer.new(t).as_json },
      reminders: reminders
    }
  end

  private

  attr_reader :user, :range

  def transactions
    user.transactions.where(transaction_date: range)
        .includes(:category, :currency, :transaction_type, :icon, :color)
        .order(transaction_date: :asc, created_at: :asc)
  end

  def reminders
    user.obligatory_payments
        .includes(:category, :icon, recurrence: :frequency_type)
        .flat_map { |payment| occurrences_for(payment) }
        .sort_by { |entry| entry[:date] }
  end

  def occurrences_for(payment)
    payment.occurrences_in_range(range.begin, range.end).map do |date|
      { id: payment.id, name: payment.name, amount: payment.amount.to_f, date:,
        reminder_type: payment.reminder_type, category_name: payment.category&.name,
        icon: payment.icon&.value }
    end
  end
end
