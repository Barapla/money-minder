# frozen_string_literal: true

# ObligatoryPaymentsController maneja los pagos obligatorios del usuario autenticado.
class ObligatoryPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_obligatory_payment, only: %i[show edit update destroy]

  # GET /obligatory_payments or /obligatory_payments.json
  def index
    @obligatory_payments = current_user.obligatory_payments.includes(:category, :color, :icon, :recurrence)
  end

  # GET /obligatory_payments/1 or /obligatory_payments/1.json
  def show; end

  # GET /obligatory_payments/new
  def new
    @obligatory_payment = ObligatoryPayment.new
    @obligatory_payment.build_recurrence
  end

  # GET /obligatory_payments/1/edit
  def edit
    @obligatory_payment.build_recurrence unless @obligatory_payment.get_recurrence
  end

  # POST /obligatory_payments or /obligatory_payments.json
  def create
    @obligatory_payment = current_user.obligatory_payments.build(obligatory_payment_params)

    respond_to do |format|
      if @obligatory_payment.save
        format.html { redirect_to obligatory_payments_url, notice: t('obligatory_payments.create.success') }
        format.json { render :show, status: :created, location: @obligatory_payment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @obligatory_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /obligatory_payments/1 or /obligatory_payments/1.json
  def update
    respond_to do |format|
      if @obligatory_payment.update(obligatory_payment_params)
        format.html { redirect_to obligatory_payments_url, notice: t('obligatory_payments.update.success') }
        format.json { render :show, status: :ok, location: @obligatory_payment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @obligatory_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /obligatory_payments/1 or /obligatory_payments/1.json
  def destroy
    @obligatory_payment.destroy

    respond_to do |format|
      format.html { redirect_to obligatory_payments_url, notice: t('obligatory_payments.destroy.success') }
      format.json { head :no_content }
    end
  end

  private

  def set_obligatory_payment
    @obligatory_payment = current_user.obligatory_payments.find(params[:id])
  end

  def obligatory_payment_params
    params.require(:obligatory_payment).permit(
      :name, :amount, :category_id, :description, :color_id, :icon_id,
      recurrence_attributes: %i[
        id frequency_type_id recurrenceable_type_id frequency_value
        day_of_month day_of_week month_of_year start_date end_date _destroy
      ]
    )
  end
end
