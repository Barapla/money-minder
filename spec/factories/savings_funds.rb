FactoryBot.define do
  factory :savings_fund do
    goal_amount { "9.99" }
    target_date { "2025-07-06" }
    monthly_contribution { "9.99" }
    interest_rate { "9.99" }
    compound_frequency_id { 1 }
    minimum_balance { "9.99" }
    account_number { "MyString" }
    account_type_id { 1 }
    auto_transfer { false }
    transfer_day { 1 }
    next_contribution_date { "2025-07-06" }
    early_withdrawal_penalty { "9.99" }
    withdrawal_limit { 1 }
    has_withdrawal_restrictions { false }
    maturity_date { "2025-07-06" }
    last_interest_payment { "2025-07-06" }
    low_balance_alert { "9.99" }
    goal_milestone_alerts { false }
    budget_id { 1 }
  end
end
