# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    sequence(:title) { |n| "Conversación #{n}" }
    association :user
  end
end
