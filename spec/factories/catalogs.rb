FactoryBot.define do
  factory :catalog do
    sequence(:value) { |n| "Value #{n}" }
    sequence(:code) { |n| "code_#{n}" }
    association :group_catalog
  end
end
