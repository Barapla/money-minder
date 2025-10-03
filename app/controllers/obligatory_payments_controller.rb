class ObligatoryPaymentsController < ApplicationController
  before_action :set_obligatory_payment, only: %i[ show edit update destroy ]

  # GET /obligatory_payments or /obligatory_payments.json
  def index
    @obligatory_payments = ObligatoryPayment.all
  end

  # GET /obligatory_payments/1 or /obligatory_payments/1.json
  def show
  end

  # GET /obligatory_payments/new
  def new
    @obligatory_payment = ObligatoryPayment.new
  end

  # GET /obligatory_payments/1/edit
  def edit
  end

  # POST /obligatory_payments or /obligatory_payments.json
  def create
    @obligatory_payment = ObligatoryPayment.new(obligatory_payment_params)

    respond_to do |format|
      if @obligatory_payment.save
        format.html { redirect_to obligatory_payment_url(@obligatory_payment), notice: "Obligatory payment was successfully created." }
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
        format.html { redirect_to obligatory_payment_url(@obligatory_payment), notice: "Obligatory payment was successfully updated." }
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
      format.html { redirect_to obligatory_payments_url, notice: "Obligatory payment was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_obligatory_payment
      @obligatory_payment = ObligatoryPayment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def obligatory_payment_params
      params.require(:obligatory_payment).permit(:user_id, :name, :amount, :category_id, :description, :color_id, :icon_id)
    end
end
