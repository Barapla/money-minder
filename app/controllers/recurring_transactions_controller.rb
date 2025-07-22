# frozen_string_literal: true

# RecurringTransactionsController handles the display and management of transactions.
class RecurringTransactionsController < ApplicationController
  def new_modal
    @transaction = Transaction.find(params[:transaction_id]) if params[:transaction_id].present?
    render layout: false if turbo_frame_request?
  end

  def create
    recurring_transaction = RecurringTransaction.new(all_params)
    transaction = Transaction.find(recurring_transaction.transaction_options['id'])

    if recurring_transaction.save
      redirect_to transaction, notice: t('recurring_transactions.create.success')
    else
      redirect_to transaction,
                  alert: t('recurring_transactions.create.error',
                           errors: recurring_transaction.errors.full_messages.join(', '))
    end
  end

  private

  def all_params
    recurring_transaction_params.merge(transaction_options: transaction_option_params, user: current_user)
  end

  def recurring_transaction_params
    params.require(:recurring_transaction).permit(:frequency, :start_date, :end_date, :max_executions,
                                                  :auto_approve)
  end

  def transaction_option_params
    params.require(:transaction).permit(:id, :amount, :description, :category_id, :color_id,
                                        :icon_id, :budget_id, :transaction_type_id)
  end
end
