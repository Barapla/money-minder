require 'rails_helper'

RSpec.describe "obligatory_payments/edit", type: :view do
  let(:obligatory_payment) {
    ObligatoryPayment.create!(
      user: nil,
      name: "MyString",
      amount: "9.99",
      category: nil,
      description: "MyText",
      color: nil,
      icon: nil
    )
  }

  before(:each) do
    assign(:obligatory_payment, obligatory_payment)
  end

  it "renders the edit obligatory_payment form" do
    render

    assert_select "form[action=?][method=?]", obligatory_payment_path(obligatory_payment), "post" do

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
