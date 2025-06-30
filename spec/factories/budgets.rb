FactoryBot.define do
  factory :budget do
    current_amount { "9.99" }
    limit_amount { "9.99" }
    budget_type { nil }
    color { nil }
    icon { nil }
  end
end
