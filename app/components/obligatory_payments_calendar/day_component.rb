# frozen_string_literal: true

module ObligatoryPaymentsCalendar
  # DayComponent
  class DayComponent < ObligatoryPaymentsCalendar::ApplicationComponent
    include PaginationHelper
    attr_reader :date, :objects, :day_total, :has_payments, :payment_count

    def initialize(date:, objects:, day_total:, options: {})
      @id = options[:id]
      @date = date
      @objects = objects
      @day_total = day_total
      @has_payments = options[:has_payments]
      @payment_count = options[:payment_count]
      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end
  end
end
