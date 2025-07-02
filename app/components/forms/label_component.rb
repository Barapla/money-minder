# frozen_string_literal: true

module Forms
  # LabelComponent
  class LabelComponent < Forms::ApplicationComponent
    attr_reader :name, :text, :required

    def initialize(form:, name:, text: nil, required: false, options: {})
      @name = name
      @text = text
      @required = required
      super(form:, options:)
    end

    private

    def label_text
      return text if text.present?

      # Usar las traducciones de ActiveRecord
      form.object.class.human_attribute_name(name)
    end

    def label_classes
      'form-label'
    end

    def required_indicator
      required ? '<span class="text-red-400 ml-1">*</span>'.html_safe : ''
    end
  end
end
