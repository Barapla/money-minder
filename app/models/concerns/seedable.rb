# frozen_string_literal: true

# Ejemplo de extensión para modelos que necesiten lógica específica
# app/models/concerns/seedable.rb
module Seedable
  extend ActiveSupport::Concern

  class_methods do
    def seed_unique_keys
      # Sobreescribe esto en el modelo si necesitas keys específicas
      [:name]
    end
  end
end
