# frozen_string_literal: true

module Table
  # MainComponent
  class MainComponent < Table::ApplicationComponent
    attr_reader :title, :headers, :values

    def initialize(title:, headers:, values:, options: {})
      @title = title
      @headers = headers.push({ name: 'Acciones', size: 'min-w-[120px]' })
      @values = values
      super(options:)
    end
  end
end
