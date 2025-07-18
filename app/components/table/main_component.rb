# frozen_string_literal: true

module Table
  # MainComponent
  class MainComponent < Table::ApplicationComponent
    include PaginationHelper
    attr_reader :url, :title, :headers, :values, :total_collections

    def initialize(url:, title:, headers:, values:, options: {})
      @url = url
      @id = options[:id]
      @total_collections = options[:total_collections]
      @title = title
      @headers = headers.push({ name: 'Acciones', size: 'min-w-[120px]' })
      @values = values
      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end
  end
end
