FactoryBot.define do
  factory :budget do
    sequence(:name) { |n| "Budget #{n}" }
    current_amount { '9.99' }
    association :user
    association :budget_type, factory: :catalog
    association :color, factory: :catalog
    association :icon, factory: :catalog
  end
end
