# frozen_string_literal: true

module Forms
  # InputFieldComponent
  class InputComponent < Forms::ApplicationComponent
    attr_reader :name, :type

    def initialize(name:, form:, type: 'text', options: {})
      @name = name
      @type = type
      super(form:, options:)
    end
  end
end
