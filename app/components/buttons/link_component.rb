# frozen_string_literal: true

module Buttons
  # LinkComponent
  class LinkComponent < Buttons::ApplicationComponent
    attr_reader :content

    def initialize(content:, href:, options: {})
      @content = content
      super(href:, options:)
    end
  end
end
