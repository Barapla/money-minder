# frozen_string_literal: true

FactoryBot.define do
  factory :obligatory_payment do
    sequence(:name) { |n| "Pago obligatorio #{n}" }
    amount { 9.99 }
    description { 'MyText' }
    reminder_type { 'payment' }
    association :user
    association :category
    association :color, factory: :catalog
    association :icon, factory: :catalog
  end
end
