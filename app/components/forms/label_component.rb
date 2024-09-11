# frozen_string_literal: true

module Forms
  # InputFieldComponent
  class LabelComponent < ApplicationComponent
    attr_reader :name, :form, :options

    def initialize(name:, form:, options: {})
      @name = name
      @form = form
      @options = options
    end
  end
end
