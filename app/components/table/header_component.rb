# frozen_string_literal: true

module Table
  # HeaderComponent
  class HeaderComponent < Table::ApplicationComponent
    attr_reader :name, :size

    def initialize(name:, size:, options: {})
      @name = name
      @size = size
      super(options:)
    end
  end
end
