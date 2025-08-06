# frozen_string_literal: true

module Charts
  # DistributionComponent
  class DistributionComponent < Charts::ApplicationComponent
    attr_reader :datasets

    def initialize(datasets:, options: {})
      @datasets = datasets
      super(options:)
    end
  end
end
