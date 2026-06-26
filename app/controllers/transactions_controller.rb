# frozen_string_literal: true

# TransactionsController handles the display and management of transactions.
class TransactionsController < ApplicationController
  include PaginationHelper
  include TransactionsHelper
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy]

  # GET /transactions or /transactions.json
  def index
    transactions = current_user.transactions.order(transaction_date: :desc).order(created_at: :desc)
    @total_collections = transactions.count
    @transactions = transactions.limit(10)
  end

  def transactions_table
    id = params[:id]
    current_page = params[:page]
    per_page = params[:perPage].to_i

    transactions = current_user.transactions.order(transaction_date: :desc).order(created_at: :desc)

    total_transactions = transactions.count

    transactions = transactions.offset(
      (current_page.to_i - 1) * per_page.to_i
    ).limit(per_page)

    total_pages = total_pages(per_page, total_transactions)
    pagination_pages = pagination_pages(current_page, total_pages)

    @transactions = values_table_transactions_format(transactions)
    stream = turbo_stream.update("table-#{id}", partial: 'components/table/main/table',
                                                locals: { headers: headers_table_transactions_index.push({ name: 'Acciones', size: 'min-w-[120px]' }),
                                                          values: @transactions, id:, per_page:, current_page:,
                                                          total_collections: total_transactions,
                                                          total_pages:, pagination_pages: })
    respond_to do |format|
      format.turbo_stream { render turbo_stream: stream }
    end
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
    @budgets = current_user.budgets.order(:name)
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
    @budgets = current_user.budgets.order(:name)
  end

  # POST /transactions or /transactions.json
  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.user = current_user

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to transaction_url(@transaction), notice: t('transactions.create.success') }
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
        format.html { redirect_to transaction_url(@transaction), notice: t('transactions.update.success') }
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
      format.html { redirect_to transactions_url, notice: t('transactions.destroy.success') }
      format.json { head :no_content }
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:transaction_type_id,
                                        :amount,
                                        :description,
                                        :category_id,
                                        :transaction_date,
                                        :budget_id,
                                        :related_budget_id,
                                        :icon_id,
                                        :color_id)
  end

  def get_turbo_stream_for_transaction_type(transaction_type)
    streams = [
      turbo_stream.update(
        'categories_frame',
        partial: "transactions/forms/#{transaction_type.code}/categories",
        locals: { transaction: Transaction.new(transaction_type:) }
      )
    ]

    streams << if transaction_type.code == 'transfer'
                 turbo_stream.update(
                   'budget_related_frame',
                   partial: 'transactions/forms/transfer/budget_related',
                   locals: { transaction: Transaction.new(transaction_type:) }
                 )
               else
                 turbo_stream.update(
                   'budget_related_frame',
                   ''
                 )
               end

    streams
  end
end
