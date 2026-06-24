# frozen_string_literal: true

FactoryBot.define do
  factory :saving_goal do
    sequence(:name) { |n| "Meta #{n}" }
    target_amount { 50_000.00 }
    deadline { nil }
    status { :active }
    association :user
  end
end
