FactoryBot.define do
  factory :credit_card_tier do
    name { "MyString" }
    level { 1 }
    recommendation_utilization { "9.99" }
    credit_score_weight { "9.99" }
    description { "MyText" }
  end
end
