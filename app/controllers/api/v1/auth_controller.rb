# frozen_string_literal: true

module Api
  module V1
    # Endpoints JSON de autenticacion y cuenta para la app movil.
    #
    # POST  /api/v1/auth/login     { email, password }                 → { record: { token, expires_at } }
    # POST  /api/v1/auth/register  { name, email, password, password_confirmation }
    #                                                                  → 201 { record: { token, expires_at } }
    # POST  /api/v1/auth/password  { email }                           → 200 siempre (no revela si el correo existe)
    # GET   /api/v1/auth/me                                            → { record: { id, email, name, currency } }
    # PATCH /api/v1/auth/me        { name, currency_id }               → { record: ... }
    # PATCH /api/v1/auth/password  { current_password, password, password_confirmation } → { record: ... }
    class AuthController < ApplicationController
      include Api::JwtAuthenticatable
      skip_before_action :authenticate_api_user!, only: %i[login register reset_password]

      def login
        user = User.find_by(email: params[:email])

        if user&.valid_password?(params[:password])
          render json: { record: user.generate_jwt_token }, status: :ok
        else
          render json: { errors: ['Credenciales inválidas'] }, status: :unauthorized
        end
      end

      def register
        user = User.new(params.permit(:name, :email, :password, :password_confirmation))
        return render_validation_errors(user) unless user.save

        render json: { record: user.generate_jwt_token }, status: :created
      end

      def reset_password
        User.send_reset_password_instructions(email: params[:email].to_s)
        render json: { record: { sent: true } }, status: :ok
      end

      def me
        render_me
      end

      def update_me
        return render_validation_errors(current_api_user) unless current_api_user.update(profile_params)

        render_me
      end

      def update_password
        updated = current_api_user.update_with_password(
          params.permit(:current_password, :password, :password_confirmation)
        )
        return render_validation_errors(current_api_user) unless updated

        render_me
      end

      private

      def profile_params
        params.permit(:name, :currency_id)
      end

      def render_me
        render json: { record: UserSerializer.new(current_api_user).as_json }, status: :ok
      end
    end
  end
end
