# frozen_string_literal: true

# Application controller
class ApplicationController < ActionController::Base
  include NavbarHelper
  include UserScoped
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private

  # Cachea la consulta/generación del reporte IA por 15 minutos: evita golpear la BD
  # (y, en caso de expirar, disparar una generación síncrona vía Claude API) en cada carga
  # del dashboard o de reportes.
  def latest_ai_financial_report
    Rails.cache.fetch("ai_financial_report/#{current_user.id}/general", expires_in: 15.minutes) do
      AiReport.latest_for_user_and_type(current_user.id, 'general')
    end
  end

  def handle_not_found
    respond_to do |format|
      format.html { render 'errors/not_found', layout: 'application', status: :not_found }
      format.json do
        render json: { error: { code: 'not_found', message: 'Recurso no encontrado' } },
               status: :not_found
      end
      format.any { head :not_found }
    end
  end
end
