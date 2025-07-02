# frozen_string_literal: true

# This module provides utility methods and shared functionality for the application.
module Utils
  extend ActiveSupport::Concern

  class_methods do
    def self.foreign_key_for(model_class)
      # Convertir a string si se pasa como símbolo o clase
      model_name = get_model_name(model_class)

      # Buscar la asociación que corresponde al modelo
      association = reflections.values.find do |reflection|
        reflection.class_name == model_name
      end

      association&.foreign_key&.to_sym
    end

    private

    def get_model_name(model_class)
      # Convertir a string si se pasa como símbolo o clase
      case model_class
      when Class
        model_class.name
      when String
        model_class
      when Symbol
        model_class.to_s.classify
      end
    end
  end
end
