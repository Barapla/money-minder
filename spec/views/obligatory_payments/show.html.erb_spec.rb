require 'rails_helper'

RSpec.describe "obligatory_payments/show", type: :view do
  before(:each) do
    assign(:obligatory_payment, ObligatoryPayment.create!(
      user: nil,
      name: "Name",
      amount: "9.99",
      category: nil,
      description: "MyText",
      color: nil,
      icon: nil
    ))
  end

  it "renders attributes in <p>" do
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
