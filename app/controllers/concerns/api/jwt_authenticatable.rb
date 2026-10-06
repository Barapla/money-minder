# frozen_string_literal: true

module Api
  # Autentica requests de API via JWT (header Authorization: Bearer <token>).
  # La API no usa cookies de sesion, asi que no aplica la proteccion CSRF.
  module JwtAuthenticatable
    extend ActiveSupport::Concern

    included do
      skip_forgery_protection
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

    # 422 con el formato de error estandar: el primer mensaje legible en
    # `message` y todos los errores por campo en `details`.
    def render_validation_errors(record)
      render json: {
        error: {
          code: 'validation_error',
          message: record.errors.full_messages.first,
          details: record.errors.to_hash
        }
      }, status: :unprocessable_entity
    end
  end
end
