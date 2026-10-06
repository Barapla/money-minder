# frozen_string_literal: true

module ObligatoryPaymentsCalendar
  # MainComponent
  class MainComponent < ObligatoryPaymentsCalendar::ApplicationComponent
    include PaginationHelper
    attr_reader :title, :date, :first_day, :last_day, :dates_array, :payment_occurrences, :id

    def initialize(title:, date:, payment_occurrences:, payroll_reminders: {}, options: {})
      @id = options[:id]
      @title = title
      @date = date
      @first_day = date.beginning_of_month.wday
      @last_day = date.end_of_month.day
      @payment_occurrences = payment_occurrences
      @payroll_reminders = payroll_reminders || {}
      @dates_array = build_dates_array

      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end

    def build_dates_array
      (1..last_day).map do |day|
        current_date = date.change(day: day)
        day_payments = payment_occurrences[current_date] || []
        day_payroll = @payroll_reminders[current_date] || []

        {
          date: current_date,
          objects: day_payments,
          has_payments: day_payments.any?,
          day_total: day_payments.sum(&:amount),
          payment_count: day_payments.count,
          has_payroll: day_payroll.any?,
          payroll_reminders: day_payroll
        }
      end
    end
  end
end
