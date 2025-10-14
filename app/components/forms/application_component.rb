# frozen_string_literal: true

module Forms
  # InputFieldComponent
  class ApplicationComponent < ::ApplicationComponent
    attr_reader :form

    def initialize(form: nil, options: {})
      @form = form
      super(options:)
    end
  end
end
