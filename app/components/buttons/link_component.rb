# frozen_string_literal: true

module Buttons
  # LinkComponent
  class LinkComponent < Buttons::ApplicationComponent
    attr_reader :text

    def initialize(text:, href:, options: {})
      @text = text
      super(href:, options:)
    end
  end
end
