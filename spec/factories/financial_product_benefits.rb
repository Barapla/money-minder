# frozen_string_literal: true

FactoryBot.define do
  factory :financial_product_benefit do
    benefit_type { :annual_yield }
    base_value { 10.0 }
    reduced_value { nil }
    amount_cap { nil }
    unit { :percentage }
    description { nil }
    active { true }
    association :financial_product

    trait :with_reduced_value do
      reduced_value { 5.0 }
    end

    trait :with_amount_cap do
      amount_cap { 25_000.0 }
    end

    trait :cashback do
      benefit_type { :cashback }
      base_value { 2.0 }
    end

    trait :points do
      benefit_type { :points }
      base_value { 1000.0 }
      unit { :points }
    end

    trait :fixed_amount do
      benefit_type { :discount }
      base_value { 100.0 }
      unit { :fixed_amount }
    end

    trait :inactive do
      active { false }
    end
  end
end
