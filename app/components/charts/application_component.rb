# frozen_string_literal: true

module Charts
  # InputFieldComponent
  class ApplicationComponent < ::ApplicationComponent
    attr_reader :title, :url

    def initialize(title:, url:, options: {})
      @id = options[:id]
      @title = title
      @url = url
      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end
  end
end
