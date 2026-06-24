# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    amount { 100.00 }
    description { Faker::Lorem.sentence }
    transaction_date { Date.today }
    association :user
    association :budget
    association :category
    association :currency
    association :color, factory: :catalog
    association :icon, factory: :catalog
    association :transaction_type, factory: :catalog
  end
end
