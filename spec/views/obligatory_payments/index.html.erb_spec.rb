require 'rails_helper'

RSpec.describe "obligatory_payments/index", type: :view do
  before(:each) do
    assign(:obligatory_payments, [
      ObligatoryPayment.create!(
        user: nil,
        name: "Name",
        amount: "9.99",
        category: nil,
        description: "MyText",
        color: nil,
        icon: nil
      ),
      ObligatoryPayment.create!(
        user: nil,
        name: "Name",
        amount: "9.99",
        category: nil,
        description: "MyText",
        color: nil,
        icon: nil
      )
    ])
  end

  it "renders a list of obligatory_payments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
