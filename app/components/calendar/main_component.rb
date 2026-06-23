# frozen_string_literal: true

module Calendar
  # MainComponent
  class MainComponent < Calendar::ApplicationComponent
    include PaginationHelper
    attr_reader :title, :date, :first_day, :last_day, :dates_array, :transactions, :id

    def initialize(title:, date:, transactions:, payroll_reminders: {}, options: {})
      @id = options[:id]
      @title = title
      @date = date
      @first_day = date.beginning_of_month.wday
      @last_day = date.end_of_month.day
      @transactions = transactions
      @payroll_reminders = payroll_reminders || {}
      @dates_array = build_dates_array

      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end

    def build_dates_array
      grouped_transactions = transactions.group_by(&:transaction_date)
      (1..last_day).map do |day|
        current_date = date.change(day: day)
        build_day_entry(current_date, grouped_transactions[current_date] || [])
      end
    end

    private

    def build_day_entry(current_date, day_transactions)
      day_payroll = @payroll_reminders[current_date] || []
      {
        date: current_date,
        objects: day_transactions,
        payroll_reminders: day_payroll,
        has_income: day_transactions.any? { |t| t.transaction_type.code == 'income' },
        has_expenses: day_transactions.any? { |t| t.transaction_type.code == 'expense' },
        has_payroll: day_payroll.any?,
        day_balance: calculate_balance(day_transactions)
      }
    end

    def calculate_balance(day_transactions)
      day_transactions.sum do |t|
          t.amount * (t.transaction_type.code == 'income' ? 1 : -1)
      end
    end
  end
end
