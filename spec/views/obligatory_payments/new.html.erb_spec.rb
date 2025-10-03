require 'rails_helper'

RSpec.describe "obligatory_payments/new", type: :view do
  before(:each) do
    assign(:obligatory_payment, ObligatoryPayment.new(
      user: nil,
      name: "MyString",
      amount: "9.99",
      category: nil,
      description: "MyText",
      color: nil,
      icon: nil
    ))
  end

  it "renders new obligatory_payment form" do
    render

    assert_select "form[action=?][method=?]", obligatory_payments_path, "post" do

      assert_select "input[name=?]", "obligatory_payment[user_id]"

      assert_select "input[name=?]", "obligatory_payment[name]"

      assert_select "input[name=?]", "obligatory_payment[amount]"

      assert_select "input[name=?]", "obligatory_payment[category_id]"

      assert_select "textarea[name=?]", "obligatory_payment[description]"

      assert_select "input[name=?]", "obligatory_payment[color_id]"

      assert_select "input[name=?]", "obligatory_payment[icon_id]"
    end
  end
end
