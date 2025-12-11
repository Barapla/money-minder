FactoryBot.define do
  factory :credit_score_event do
    credit_card { nil }
    credit_card_cycle { nil }
    event_type { 1 }
    impact { 1 }
    event_date { "2025-12-07" }
    amount { "9.99" }
    notes { "MyText" }
    auto_generated { false }
  end
end
