# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'obligatory_payments/index', type: :view do
  before(:each) do
    payments = (1..2).map do |i|
      op = ObligatoryPayment.new(name: 'Name', amount: '9.99', description: 'MyText')
      allow(op).to receive(:id).and_return(i)
      allow(op).to receive(:to_param).and_return(i.to_s)
      allow(op).to receive(:persisted?).and_return(true)
      op
    end
    assign(:obligatory_payments, payments)
  end

  it 'renders a list of obligatory_payments' do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/9.99/)
  end
end
