# frozen_string_literal: true

module Admin
  # CRUD de productos financieros para administradores.
  class FinancialProductsController < Admin::ApplicationController
    before_action :set_financial_product, only: %i[edit update]

    def index
      @products = FinancialProduct.includes(:financial_institution).alphabetical
      @products = @products.active if params[:active_only] == 'true'
      @grouped_products = @products.group_by(&:financial_institution)
    end

    def new
      @financial_product = FinancialProduct.new
      @institutions = FinancialInstitution.active.alphabetical
    end

    def create
      @financial_product = FinancialProduct.new(financial_product_params)

      if @financial_product.save
        redirect_to admin_financial_products_path, notice: t('.success')
      else
        @institutions = FinancialInstitution.active.alphabetical
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @institutions = FinancialInstitution.active.alphabetical
    end

    def update
      if @financial_product.update(financial_product_params)
        redirect_to admin_financial_products_path, notice: t('.success')
      else
        @institutions = FinancialInstitution.active.alphabetical
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_financial_product
      @financial_product = FinancialProduct.find(params[:id])
    end

    def financial_product_params
      params.require(:financial_product).permit(:name, :product_type, :financial_institution_id, :active)
    end
  end
end
