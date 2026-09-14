# frozen_string_literal: true

module Api
  # Autentica requests de API via JWT (header Authorization: Bearer <token>).
  module JwtAuthenticatable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_user!
      attr_reader :current_api_user
    end

    private

    def authenticate_api_user!
      token = request.headers['Authorization']&.split(' ')&.last
      decoded = token.present? ? User.decode_jwt_token(token) : nil
      @current_api_user = decoded && User.find_by(id: decoded[0]['user_id'])

      return if @current_api_user

      render json: { errors: ['Token inválido o expirado'] }, status: :unauthorized
    end
  end
end
