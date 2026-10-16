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
      user = user_from_token
      # Un token emitido antes de bloquear la cuenta (o de vencer el plazo para
      # confirmar el correo) deja de servir en ese momento, no 30 dias despues.
      @current_api_user = user if user&.active_for_authentication?

      return if @current_api_user

      render json: { errors: ['Token inválido o expirado'] }, status: :unauthorized
    end

    # 422 con el formato de error estandar: el primer mensaje legible en
    # `message` y todos los errores por campo en `details`.
    def user_from_token
      token = request.headers['Authorization']&.split(' ')&.last
      decoded = token.present? ? User.decode_jwt_token(token) : nil
      decoded && User.find_by(id: decoded[0]['user_id'])
    end

    def render_rate_limited
      render json: { error: { code: 'rate_limited', message: I18n.t('rate_limit.too_many_attempts') } },
             status: :too_many_requests
    end

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
