FactoryBot.define do
  factory :transaction_history do
    transaction { nil }
    pre_amount { "9.99" }
    post_amount { "9.99" }
  end
end
