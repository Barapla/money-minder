# frozen_string_literal: true

# app/components/forms/checkbox/simple_component.rb
module Forms
  module Checkbox
    # SimpleComponent
    class SimpleComponent < BaseComponent
      def initialize(name:, form: nil, options: {})
        super(name:, form:, options:)
      end
    end
  end
end
