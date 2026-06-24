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
