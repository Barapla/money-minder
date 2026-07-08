# frozen_string_literal: true

module Admin
  # Base controller para el namespace admin.
  class ApplicationController < ::ApplicationController
    before_action :authenticate_user!
    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      redirect_to root_path, alert: t('errors.not_authorized')
    end
  end
end
