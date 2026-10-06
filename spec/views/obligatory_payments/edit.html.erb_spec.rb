# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'obligatory_payments/edit', type: :view do
  let(:obligatory_payment) do
    op = ObligatoryPayment.new(name: 'MyString', amount: '9.99', description: 'MyText')
    allow(op).to receive(:id).and_return(1)
    allow(op).to receive(:to_param).and_return('1')
    allow(op).to receive(:persisted?).and_return(true)
    op
  end

  before(:each) do
    assign(:obligatory_payment, obligatory_payment)
  end

  it 'renders the edit obligatory_payment form' do
    render

    assert_select 'form[action=?][method=?]', obligatory_payment_path(obligatory_payment), 'post'
  end
end
