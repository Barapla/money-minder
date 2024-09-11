# frozen_string_literal: true

module Forms
  # InputFieldComponent
  class InputComponent < ApplicationComponent
    attr_reader :name, :form, :type, :options

    def initialize(name:, form:, type: 'text', options: {})
      @name = name
      @form = form
      @type = type
      @options = options
    end
  end
end
