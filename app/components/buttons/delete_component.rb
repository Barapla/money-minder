# frozen_string_literal: true

module Buttons
  # DeleteComponent
  class DeleteComponent < Buttons::ApplicationComponent
    attr_reader :content

    def initialize(content:, href:, options: {})
      @content = content
      super(href:, options:)
    end
  end
end
