# frozen_string_literal: true

# app/components/forms/radio_component.rb
module Forms
  # SpecialRadioComponent
  class SpecialRadioComponent < Forms::ApplicationComponent
    attr_reader :name, :collection, :default_object_value, :default_object_label, :help_text, :required,
                :collection_options

    def initialize(name:, form:, collection:, options: {})
      @name = name
      @collection = collection
      @default_object_value = options.delete(:default_object_value) || 'id'
      @default_object_label = options.delete(:default_object_label) || 'name'
      @help_text = options.delete(:help_text)
      @required = options.delete(:required) { false }
      @collection_options = options.delete(:collection_options) || {}
      super(form:, options:)
    end

    def button_classes(object, is_colors)
      if is_colors
        "form-radio-btn-colors bg-#{object[default_object_label]}"
      else
        'form-radio-btn'
      end
    end

    def data_collection_options(object, is_colors)
      data = collection_options[:data] || {}
      data.merge!(color_class: "bg-#{object[default_object_label]}") if is_colors
      data
    end
  end
end
