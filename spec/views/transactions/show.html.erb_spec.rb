# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'transactions/show', type: :view do
  before(:each) do
    transaction = Transaction.new
    allow(transaction).to receive(:id).and_return(1)
    allow(transaction).to receive(:to_param).and_return('1')
    allow(transaction).to receive(:persisted?).and_return(true)
    assign(:transaction, transaction)
    assign(:transaction_presenter, TransactionPresenter.new(transaction))
  end

  it 'renders attributes in <p>' do
    pending 'Requiere transaccion con todas las asociaciones necesarias (transaction_type, icon, color)'
    render
  end
end
