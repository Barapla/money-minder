FactoryBot.define do
  factory :credit_card_product do
    financial_institution { nil }
    credit_card_tier { nil }
    name { "MyString" }
    code { "MyString" }
    cycle_calculation_type { 1 }
    default_cutting_day { 1 }
    cycle_days { 1 }
    payment_grace_days { 1 }
    default_interest_rate { "9.99" }
    minimum_payment_calculation { 1 }
    minimum_payment_value { "9.99" }
    annual_fee { "9.99" }
    reports_to_buro { false }
    benefits { "" }
    reward_type { "MyString" }
  end
end
