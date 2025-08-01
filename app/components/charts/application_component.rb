# frozen_string_literal: true

module Charts
  # InputFieldComponent
  class ApplicationComponent < ::ApplicationComponent
    # attr_reader :form

    def initialize(options: {})
      @id = options[:id]
      super(options:)
    end

    def id
      @id ||= SecureRandom.hex(6)
    end
  end
end
