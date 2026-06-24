# frozen_string_literal: true

FactoryBot.define do
  factory :saving_goal do
    sequence(:name) { |n| "Meta #{n}" }
    target_amount { 50_000.00 }
    deadline { nil }
    status { :active }
    association :user
    # priority_order se asigna automáticamente via before_validation callback
  end
end
