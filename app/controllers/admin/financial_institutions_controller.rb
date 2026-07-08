# frozen_string_literal: true

module Admin
  # CRUD de instituciones financieras para administradores.
  class FinancialInstitutionsController < Admin::ApplicationController
    before_action :set_financial_institution, only: %i[edit update destroy]

    def index
      @financial_institutions = FinancialInstitution.alphabetical
      @financial_institutions = @financial_institutions.active if params[:active_only] == 'true'
    end

    def new
      @financial_institution = FinancialInstitution.new
    end

    def create
      @financial_institution = FinancialInstitution.new(financial_institution_params)

      if @financial_institution.save
        redirect_to admin_financial_institutions_path, notice: t('.success')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @financial_institution.update(financial_institution_params)
        redirect_to admin_financial_institutions_path, notice: t('.success')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @financial_institution.destroy
      redirect_to admin_financial_institutions_path, notice: t('.success')
    end

    private

    def set_financial_institution
      @financial_institution = FinancialInstitution.find(params[:id])
    end

    def financial_institution_params
      params.require(:financial_institution).permit(:name, :active)
    end
  end
end
