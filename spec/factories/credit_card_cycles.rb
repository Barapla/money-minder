FactoryBot.define do
  factory :credit_card_cycle do
    credit_card { nil }
    cutting_date { "2025-08-18" }
    payment_due_date { "2025-08-18" }
    statement_balance { "9.99" }
    closing_balance { "9.99" }
    minimum_payment { "9.99" }
    interest { "9.99" }
    fees { "9.99" }
    payments { "9.99" }
    purchases { "9.99" }
    status { nil }
    statement_generated_at { "2025-08-18 18:23:31" }
  end
end
