# frozen_string_literal: true

module Forms
  # InputFieldComponent
  class LabelComponent < Forms::ApplicationComponent
    attr_reader :name

    def initialize(name:, form:, options: {})
      @name = name
      super(form:, options:)
    end
  end
end
