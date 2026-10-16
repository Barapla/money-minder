# frozen_string_literal: true

# Users::SessionsController
module Users
  # SessionsController for user authentication
  class SessionsController < Devise::SessionsController
    # before_action :configure_sign_in_params, only: [:create]
    layout 'auth_application', only: %i[new]

    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to new_user_session_path, alert: t('rate_limit.too_many_attempts') }

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    # def create
    #   super
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
  end
end
