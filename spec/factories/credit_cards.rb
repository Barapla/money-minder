FactoryBot.define do
  factory :credit_card do
    current_amount { "9.99" }
    limit_amount { "9.99" }
    debt_amount { "9.99" }
    payday { "2025-07-06" }
    cutting_day { "2025-07-06" }
    budget { nil }
  end
end
