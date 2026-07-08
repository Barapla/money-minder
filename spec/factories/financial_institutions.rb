# frozen_string_literal: true

FactoryBot.define do
  factory :financial_institution do
    sequence(:name) { |n| "Institución #{n}" }
    active { true }
  end
end
