# frozen_string_literal: true

module Forms
  # ButtonSubmitComponent
  class SubmitComponent < Forms::ApplicationComponent
    attr_reader :text

    def initialize(text:, form:, options: {})
      @text = text
      super(form:, options:)
    end
  end
end
