# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/catalogs — opciones de los formularios de la app movil.
    class CatalogsController < ApplicationController
      include Api::JwtAuthenticatable

      def index
        render json: { record: CatalogOptionsSerializer.new(current_api_user).as_json }, status: :ok
      end
    end
  end
end
