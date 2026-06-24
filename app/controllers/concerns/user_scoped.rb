# frozen_string_literal: true

# Proporciona metodos de autorizacion basados en current_user para scoping de recursos.
module UserScoped
  extend ActiveSupport::Concern

  def authorize_resource(resource, user_association: :user)
    return resource if resource.public_send(user_association) == current_user

    raise ActiveRecord::RecordNotFound
  end
end
