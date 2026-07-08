# frozen_string_literal: true

module Admin
  # CRUD de beneficios de productos financieros para administradores.
  class FinancialProductBenefitsController < Admin::ApplicationController
    before_action :set_financial_product
    before_action :set_benefit, only: %i[edit update destroy]

    def index
      redirect_to admin_financial_product_path(@financial_product)
    end

    def new
      @benefit = @financial_product.benefits.build
    end

    def create
      @benefit = @financial_product.benefits.build(benefit_params)

      if @benefit.save
        redirect_to admin_financial_product_path(@financial_product), notice: t('.success')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @benefit.update(benefit_params)
        redirect_to admin_financial_product_path(@financial_product), notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @benefit.destroy
      redirect_to admin_financial_product_path(@financial_product), notice: t('.success')
    end

    private

    def set_financial_product
      @financial_product = FinancialProduct.find(params[:financial_product_id])
    end

    def set_benefit
      @benefit = @financial_product.benefits.find(params[:id])
    end

    def benefit_params
      params.require(:financial_product_benefit).permit(
        :benefit_type, :base_value, :reduced_value, :amount_cap, :unit, :description, :active
      )
    end
  end
end
