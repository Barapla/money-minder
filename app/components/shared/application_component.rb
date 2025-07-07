# frozen_string_literal: true

module Shared
  # Shared::ApplicationComponent
  class ApplicationComponent < ::ApplicationComponent
    def initialize(options: {})
      @options = options
      super
    end
  end
end
