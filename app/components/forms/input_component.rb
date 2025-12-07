# frozen_string_literal: true

module Forms
  # InputComponent
  class InputComponent < Forms::ApplicationComponent
    attr_reader :name, :type, :placeholder, :icon, :size, :prefix, :suffix, :help_text, :required

    def initialize(name:, form:, type: 'text', options: {})
      @name = name
      @type = type
      @placeholder = options.delete(:placeholder)
      @icon = options.delete(:icon)
      @size = options.delete(:size) || :md
      @prefix = options.delete(:prefix)
      @suffix = options.delete(:suffix)
      @help_text = options.delete(:help_text)
      @required = options.delete(:required) { false }
      super(form:, options:)
    end

    def field_type
      case type
      when :text_area
        :text_area
      else
        "#{type}_field".to_sym
      end
    end

    private

    def input_classes
      classes = ['form-control'] if type
      classes << size_classes if size
      classes << 'has-icon-left' if icon
      classes << 'has-prefix' if prefix
      classes << 'has-suffix' if suffix
      classes.join(' ')
    end

    def size_classes
      case size
      when :small
        'form-control-sm'
      when :large
        'form-control-lg'
      else
        'form-control-md'
      end
    end

    def wrapper_classes
      icon || prefix || suffix ? 'relative' : ''
    end

    def error_classes
      'form-control-error border-red-500 focus:border-red-500 focus:ring-red-500'
    end
  end
end
