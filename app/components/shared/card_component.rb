# frozen_string_literal: true

module Shared
  # CardComponent
  class CardComponent < Shared::ApplicationComponent
    attr_reader :title, :subtitle, :main_text, :icon

    COLORS = [
      { name: 'orange', bg_color: 'bg-orange-500/20', text_color: 'text-orange-400' },
      { name: 'emerald', bg_color: 'bg-emerald-500/20', text_color: 'text-emerald-400' },
      { name: 'purple', bg_color: 'bg-purple-500/20', text_color: 'text-purple-400' },
      { name: 'blue', bg_color: 'bg-blue-500/20', text_color: 'text-blue-400' },
      { name: 'red', bg_color: 'bg-red-500/20', text_color: 'text-red-400' },
      { name: 'yellow', bg_color: 'bg-yellow-500/20', text_color: 'text-yellow-400' }
    ].freeze

    def initialize(title:, subtitle:, main_text:, options: {})
      @title = title
      @subtitle = subtitle
      @main_text = main_text
      @color = options[:color]
      @icon = options[:icon]
      super(options:)
    end

    def text_color
      COLORS.find { |c| c[:name] == @color }[:text_color]
    end

    def bg_color
      COLORS.find { |c| c[:name] == @color }[:bg_color]
    end
  end
end
