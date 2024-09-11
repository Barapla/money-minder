# frozen_string_literal: true

module Forms
  # ButtonSubmitComponent
  class ButtonSubmitComponent < ApplicationComponent
    attr_reader :text, :form, :options

    def initialize(text:, form:, options: {})
      @text = text
      @form = form
      @options = options
    end
  end
end
