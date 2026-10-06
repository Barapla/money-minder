# frozen_string_literal: true

# ObligatoryPaymentsController maneja los pagos obligatorios del usuario autenticado.
class ObligatoryPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_obligatory_payment, only: %i[show edit update destroy]

  # GET /obligatory_payments or /obligatory_payments.json
  def index
    @obligatory_payments = current_user.obligatory_payments
                                       .includes(:category, :color, :icon, :recurrence)
                                       .by_type(params[:reminder_type])
    @obligatory_payments = apply_recurrence_filter(@obligatory_payments, params[:recurrence_filter])
  end

  # GET /obligatory_payments/1 or /obligatory_payments/1.json
  def show; end

  # GET /obligatory_payments/new
  def new
    @obligatory_payment = ObligatoryPayment.new
    @obligatory_payment.build_recurrence
  end

  # GET /obligatory_payments/1/edit
  def edit; end

  # POST /obligatory_payments or /obligatory_payments.json
  def create
    @obligatory_payment = current_user.obligatory_payments.build(creation_params)

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
      if @obligatory_payment.update(update_params)
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
      :reminder_type, :due_date, :one_time, :done,
      recurrence_attributes: %i[
        id frequency_type_id recurrenceable_type_id frequency_value
        day_of_month day_of_week month_of_year start_date end_date _destroy
      ]
    )
  end

  def creation_params
    attrs = obligatory_payment_params
    extract_one_time!(attrs)
    attrs
  end

  def update_params
    attrs = obligatory_payment_params
    mark_recurrence_for_destruction!(attrs) if extract_one_time!(attrs)
    attrs
  end

  # :one_time no es un atributo del modelo: se usa solo para decidir si se
  # descarta la recurrencia enviada por el form. Retorna true si es un recordatorio unico.
  def extract_one_time!(attrs)
    one_time = ActiveModel::Type::Boolean.new.cast(attrs.delete(:one_time))
    attrs.delete(:recurrence_attributes) if one_time
    one_time
  end

  # Marca la recurrencia existente para destruccion via nested attributes en vez de
  # destruirla de inmediato: asi la baja ocurre atomicamente dentro de la misma
  # transaccion de @obligatory_payment.update, sin dejarla a medio actualizar.
  def mark_recurrence_for_destruction!(attrs)
    recurrence = @obligatory_payment.get_recurrence
    attrs[:recurrence_attributes] = { id: recurrence.id, _destroy: '1' } if recurrence
  end

  def apply_recurrence_filter(payments, filter)
    case filter
    when 'recurring' then payments.recurring
    when 'one_time' then payments.one_time
    else payments
    end
  end
end
