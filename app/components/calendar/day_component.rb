# frozen_string_literal: true

module Calendar
  # MainComponent
  class DayComponent < Calendar::ApplicationComponent
    include PaginationHelper
    attr_reader :date, :objects, :day_balance, :has_income, :has_expenses

    def initialize(date:, objects:, day_balance:, options: {})
      @id = options[:id]
      @date = date
      @objects = objects
      @day_balance = day_balance
      @has_income = options[:has_income]
      @has_expenses = options[:has_expenses]
      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end
  end
end
