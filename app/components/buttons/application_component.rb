# frozen_string_literal: true

module Buttons
  # InputFieldComponent
  class ApplicationComponent < ::ApplicationComponent
    attr_reader :href

    def initialize(href:, options: {})
      @href = href
      super(options:)
    end
  end
end
