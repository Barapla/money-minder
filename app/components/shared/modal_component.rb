# frozen_string_literal: true

module Shared
  # ModalComponent
  class ModalComponent < Shared::ApplicationComponent
    attr_reader :title, :subtitle, :size

    SIZES = {
      small: 'max-w-2xl',
      medium: 'max-w-5xl'
    }

    def initialize(title:, subtitle:, size: :medium, options: {})
      @title = title
      @subtitle = subtitle
      @size = size
      super(options:)
    end

    def size
      SIZES[@size]
    end
  end
end
