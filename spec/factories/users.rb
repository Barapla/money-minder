# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    association :role

    after(:build) do |user|
      user.define_singleton_method(:create_personal_budget) {}
    end

    trait :admin do
      role { Role.find_or_create_by!(name: 'admin') }
    end
  end
end
