# frozen_string_literal: true

module Charts
  # InputFieldComponent
  class FlowComponent < Charts::ApplicationComponent
    attr_reader :datasets, :url

    def initialize(datasets:, url:, options: {})
      @datasets = datasets
      @url = url
      super(options:)
    end
  end
end
