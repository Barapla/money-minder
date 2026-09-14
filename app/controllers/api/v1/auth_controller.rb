# frozen_string_literal: true

module Api
  module V1
    # Endpoints JSON de autenticacion por token para la app movil.
    class AuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      include Api::JwtAuthenticatable
      skip_before_action :authenticate_api_user!, only: [:login]

      def login
        user = User.find_by(email: params[:email])

        if user&.valid_password?(params[:password])
          render json: { record: user.generate_jwt_token }, status: :ok
        else
          render json: { errors: ['Credenciales inválidas'] }, status: :unauthorized
        end
      end

      def me
        render json: { record: UserSerializer.new(current_api_user).as_json }, status: :ok
      end
    end
  end
end
