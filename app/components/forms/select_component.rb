# frozen_string_literal: true

module Forms
  # SelectComponent
  class SelectComponent < Forms::ApplicationComponent
    attr_reader :name, :options_collection, :prompt, :selected, :size, :help_text, :required, :icon

    def initialize(name:, form: nil, options_collection: [], options: {})
      @name = name
      @options_collection = options_collection
      @prompt = options.delete(:prompt)
      @selected = options.delete(:selected)
      @size = options.delete(:size) || :md
      @help_text = options.delete(:help_text)
      @required = options.delete(:required) { false }
      @icon = options.delete(:icon)
      super(form:, options:)
    end

    private

    def select_classes
      classes = ['form-control']
      classes << size_classes if size
      classes << 'has-icon-left' if icon
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
      'relative'
    end

    def chevron_icon
      '<svg class="w-5 h-5 text-bunker-400 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>'.html_safe
    end
  end
end
