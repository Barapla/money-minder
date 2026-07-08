# frozen_string_literal: true

FactoryBot.define do
  factory :financial_product_benefit_requirement do
    requirement_type { :min_transactions }
    min_transactions_count { 1 }
    min_amount_per_transaction { nil }
    min_accumulated_amount { nil }
    monthly_fee_amount { nil }
    active { true }
    association :benefit, factory: :financial_product_benefit

    trait :min_transactions do
      requirement_type { :min_transactions }
      min_transactions_count { 1 }
    end

    trait :min_transactions_with_amount do
      requirement_type { :min_transactions_with_amount }
      min_transactions_count { 4 }
      min_amount_per_transaction { 50.00 }
    end

    trait :accumulated_amount do
      requirement_type { :accumulated_amount }
      min_transactions_count { nil }
      min_accumulated_amount { 2_500.00 }
    end

    trait :monthly_fee do
      requirement_type { :monthly_fee }
      min_transactions_count { nil }
      monthly_fee_amount { 179.00 }
    end

    trait :inactive do
      active { false }
    end
  end
end
