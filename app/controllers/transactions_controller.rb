class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]

  # GET /transactions or /transactions.json
  def index
    @transactions = Transaction.all
  end

  # GET /transactions/1 or /transactions/1.json
  def show
    @transaction_presenter = TransactionPresenter.new(@transaction)
    @budget_presenter = BudgetPresenter.new(@transaction.budget)
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
    @transaction.budget_id = params[:budget_id] if params[:budget_id].present?
  end

  def change_categories
    transaction_type = Catalog.find(params[:transaction][:transaction_type_id])
    stream = get_turbo_stream_for_transaction_type(transaction_type)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: stream
      end
    end
  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions or /transactions.json
  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.currency = Currency.find_by(code: 'MXN')

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to transaction_url(@transaction), notice: 'Transaction was successfully created.' }
        format.json { render :show, status: :created, location: @transaction }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transactions/1 or /transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to transaction_url(@transaction), notice: 'Transaction was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1 or /transactions/1.json
  def destroy
    @transaction.destroy

    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'Transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def transaction_params
    params.require(:transaction).permit(:transaction_type_id,
                                        :amount,
                                        :description,
                                        :category_id,
                                        :transaction_date,
                                        :budget_id,
                                        :related_budget_id,
                                        :icon_id,
                                        :color_id,
                                        :user_id)
  end

  def get_turbo_stream_for_transaction_type(transaction_type)
    [
      turbo_stream.update(
        'categories_frame',
        partial: "transactions/forms/#{transaction_type.code}/categories",
        locals: { transaction: Transaction.new(transaction_type:) }
      )
    ]
  end
end
