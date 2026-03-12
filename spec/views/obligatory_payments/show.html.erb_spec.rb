# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'obligatory_payments/show', type: :view do
  before(:each) do
    op = ObligatoryPayment.new(name: 'Name', amount: '9.99', description: 'MyText')
    allow(op).to receive(:id).and_return(1)
    allow(op).to receive(:to_param).and_return('1')
    allow(op).to receive(:persisted?).and_return(true)
    assign(:obligatory_payment, op)
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
