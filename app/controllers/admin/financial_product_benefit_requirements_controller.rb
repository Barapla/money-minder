# frozen_string_literal: true

module Admin
  # CRUD de requisitos de beneficios de productos financieros para administradores.
  class FinancialProductBenefitRequirementsController < Admin::ApplicationController
    before_action :set_financial_product
    before_action :set_benefit
    before_action :set_requirement, only: %i[edit update destroy]

    def new
      @requirement = @benefit.requirements.build
    end

    def create
      @requirement = @benefit.requirements.build(requirement_params)

      if @requirement.save
        redirect_to admin_financial_product_benefit_path(@financial_product, @benefit),
                    notice: t('.success')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @requirement.update(requirement_params)
        redirect_to admin_financial_product_benefit_path(@financial_product, @benefit),
                    notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @requirement.update!(active: false)
      redirect_to admin_financial_product_benefit_path(@financial_product, @benefit),
                  notice: t('.success')
    end

    private

    def set_financial_product
      @financial_product = FinancialProduct.find(params[:financial_product_id])
    end

    def set_benefit
      @benefit = @financial_product.benefits.find(params[:benefit_id])
    end

    def set_requirement
      @requirement = @benefit.requirements.find(params[:id])
    end

    def requirement_params
      params.require(:financial_product_benefit_requirement).permit(
        :requirement_type,
        :min_transactions_count,
        :min_amount_per_transaction,
        :min_accumulated_amount,
        :monthly_fee_amount,
        :active
      )
    end
  end
end
