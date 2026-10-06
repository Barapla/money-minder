# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'transactions/index', type: :view do
  before(:each) do
    transactions = (1..2).map do |i|
      t = Transaction.new
      allow(t).to receive(:id).and_return(i)
      allow(t).to receive(:to_param).and_return(i.to_s)
      allow(t).to receive(:persisted?).and_return(true)
      t
    end
    assign(:transactions, transactions)
    assign(:total_collections, 2)
  end

  it 'renders a list of transactions' do
    pending 'Requiere transacciones con todas las asociaciones necesarias (transaction_type, icon, color, budget)'
    render
    'div>p'
  end
end
