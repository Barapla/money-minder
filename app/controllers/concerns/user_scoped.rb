# frozen_string_literal: true

# Proporciona metodos de autorizacion basados en current_user para scoping de recursos.
module UserScoped
  extend ActiveSupport::Concern

  ALLOWED_USER_ASSOCIATIONS = %i[user].freeze

  def authorize_resource(resource, user_association: :user)
    unless ALLOWED_USER_ASSOCIATIONS.include?(user_association.to_sym)
      raise ArgumentError, "Asociacion no permitida: #{user_association}"
    end

    return resource if resource.user == current_user

    raise ActiveRecord::RecordNotFound
  end
end
