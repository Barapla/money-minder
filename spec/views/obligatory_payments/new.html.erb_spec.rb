# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'obligatory_payments/new', type: :view do
  before(:each) do
    assign(:obligatory_payment, ObligatoryPayment.new(
                                  name: 'MyString',
                                  amount: '9.99',
                                  description: 'MyText'
                                ))
  end

  it 'renders new obligatory_payment form' do
    render

    assert_select 'form[action=?][method=?]', obligatory_payments_path, 'post'
  end
end
