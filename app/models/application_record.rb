# frozen_string_literal: true

# Application record model
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.foreign_key_for(model_class)
    # Convertir a string si se pasa como símbolo o clase
    model_name = case model_class
                 when Class
                   model_class.name
                 when String
                   model_class
                 when Symbol
                   model_class.to_s.classify
                 else
                   return nil
                 end

    # Buscar la asociación que corresponde al modelo
    association = reflections.values.find do |reflection|
      reflection.class_name == model_name
    end

    association&.foreign_key&.to_sym
  end
end
