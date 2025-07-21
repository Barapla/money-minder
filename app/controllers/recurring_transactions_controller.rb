# frozen_string_literal: true

# RecurringTransactionsController handles the display and management of transactions.
class RecurringTransactionsController < ApplicationController
  def new_modal
    @transaction = Transaction.find(params[:transaction_id]) if params[:transaction_id].present?
    render layout: false if turbo_frame_request?
  end

  def create
  end
end
