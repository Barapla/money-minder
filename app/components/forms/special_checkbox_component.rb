# frozen_string_literal: true

# app/components/forms/special_checkbox_component.rb
module Forms
  # SpecialCheckboxComponent
  class SpecialCheckboxComponent < Forms::ApplicationComponent
    attr_reader :name

    DIV_COLORS = {
      'emerald' => 'peer-checked:bg-emerald-500/20 peer-checked:border-emerald-500/50 peer-checked:text-emerald-300',
      'red' => 'peer-checked:bg-red-500/20 peer-checked:border-red-500/50 peer-checked:text-red-300',
      'blue' => 'peer-checked:bg-blue-500/20 peer-checked:border-blue-500/50 peer-checked:text-blue-300',
    }

    TEXT_COLORS = {
      'emerald' => 'peer-checked:text-emerald-400',
      'red' => 'peer-checked:text-red-400',
      'blue' => 'peer-checked:text-blue-400',
    }


    def initialize(name:, form: nil, options: {})
      @name = name,
      @color = options.delete(:color) || 'emerald'
      super(form:, options:)
    end

    def div_color
      DIV_COLORS[@color] || 'peer-checked:bg-emerald-500/20 peer-checked:border-emerald-500/50 peer-checked:text-emerald-300'
    end

    def text_color
      TEXT_COLORS[@color] || 'peer-checked:text-emerald-400'
    end

  end
end
