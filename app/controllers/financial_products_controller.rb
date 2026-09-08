# frozen_string_literal: true

# Endpoint de consulta dinamica del catalogo financiero (FEAT-026), usado por el
# Stimulus controller product_selector para poblar el select de producto una vez
# que el usuario elige una institucion.
class FinancialProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_type!

  VALID_TYPES = %w[cash debit credit savings_fund term_saving].freeze

  def index
    products = FinancialCatalogServices::Registry.by_type(params[:type].to_s)
                                                 .by_institution(params[:institution].to_s)

    render json: products.map { |product| { id: product.id, name: product.name } }
  end

  private

  def validate_type!
    render json: [] unless VALID_TYPES.include?(params[:type].to_s)
  end
end
