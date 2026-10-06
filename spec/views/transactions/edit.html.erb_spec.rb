# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'transactions/edit', type: :view do
  let(:transaction) do
    t = Transaction.new
    allow(t).to receive(:id).and_return(1)
    allow(t).to receive(:to_param).and_return('1')
    allow(t).to receive(:persisted?).and_return(true)
    t
  end

  before(:each) do
    assign(:transaction, transaction)
  end

  it 'renders the edit transaction form' do
    render

    assert_select 'form[action=?][method=?]', transaction_path(transaction), 'post' do
    end
  end
end
