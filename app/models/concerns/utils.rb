# frozen_string_literal: true

# This module provides utility methods and shared functionality for the application.
module Utils
  extend ActiveSupport::Concern

  class_methods do
    def foreign_key_for(model_class)
      # Convertir a string si se pasa como símbolo o clase
      model_name = get_model_name(model_class)

      # Buscar la asociación que corresponde al modelo
      association = find_association_for_model(model_name)

      association&.foreign_key&.to_sym
    end

    private

    def get_model_name(model_class)
      case model_class
      when Class
        model_class.name
      when String
        model_class
      when Symbol
        model_class.to_s.classify
      else
        raise ArgumentError, "Expected Class, String, or Symbol, got #{model_class.class}"
      end
    end

    def find_association_for_model(model_name)
      # Verificar que la clase tenga reflections (es un modelo ActiveRecord)
      return nil unless respond_to?(:reflections)

      reflections.values.find do |reflection|
        reflection.class_name == model_name
      end
    end
  end
end
