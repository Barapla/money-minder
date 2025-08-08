# frozen_string_literal: true

module Charts
  # DistributionComponent
  class DistributionComponent < Charts::ApplicationComponent
    attr_reader :datasets

    def initialize(title:, url:, datasets:, options: {})
      @datasets = datasets
      super(title:, url:, options:)
    end
  end
end
