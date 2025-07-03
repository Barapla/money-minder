# frozen_string_literal: true

module Table
  # TdComponent
  class TdComponent < Table::ApplicationComponent
    attr_reader :item

    def initialize(item:, options: {})
      @item = item
      super(options:)
    end
  end
end
