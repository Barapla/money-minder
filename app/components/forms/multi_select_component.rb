# frozen_string_literal: true

module Forms
  # MultiSelectComponent
  class MultiSelectComponent < Forms::ApplicationComponent
    attr_reader :name, :options_collection, :placeholder, :selected, :size, :help_text, :required, :icon, :searchable

    def initialize(name:, form:, options_collection: [], options: {})
      @name = name
      @options_collection = options_collection
      @placeholder = options.delete(:placeholder) || 'Selecciona opciones...'
      @selected = Array(options.delete(:selected) || form.object&.send(name) || [])
      @size = options.delete(:size) || :md
      @help_text = options.delete(:help_text)
      @required = options.delete(:required) { false }
      @icon = options.delete(:icon)
      @searchable = options.delete(:searchable) { true }
      super(form:, options:)
    end

    def selected_values_as_json
      @selected.to_json
    end

    def options_collection_as_json
      @options_collection.map { |option|
        if option.is_a?(Array)
          { text: option[0], value: option[1].to_s }
        else
          { text: option.to_s, value: option.to_s }
        end
      }.to_json
    end

    def hidden_options
      options[:data] ||= {}
      options[:data][:multiselect_target] = 'hiddenInput'

      options
    end

    private

    def multiselect_classes
      classes = ['multiselect-trigger']
      classes << size_classes if size
      classes << 'has-icon-left' if icon
      classes.join(' ')
    end

    def size_classes
      case size
      when :small
        'multiselect-sm'
      when :large
        'multiselect-lg'
      else
        'multiselect-md'
      end
    end

    def wrapper_classes
      'relative multiselect-wrapper'
    end

    def chevron_icon
      '<svg class="w-5 h-5 text-bunker-400 pointer-events-none transition-transform duration-200"
            data-multiselect-target="chevron"
            fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>'.html_safe
    end

    def search_icon
      '<svg class="w-4 h-4 text-bunker-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
      </svg>'.html_safe
    end
  end
end
