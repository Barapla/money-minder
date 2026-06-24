# frozen_string_literal: true

# Dashboard financiero: agrega saldos, tarjetas y alertas del usuario.
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @presenter = DashboardPresenter.new(current_user)
  end
end
