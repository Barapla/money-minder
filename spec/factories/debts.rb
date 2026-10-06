# frozen_string_literal: true

FactoryBot.define do
  factory :debt do
    association :user
    direction { :receivable }
    status { :active }
    sequence(:name) { |n| "Deuda #{n}" }
    counterparty { 'Luis' }
    principal_amount { 25_000 }
    installment_amount { 250 }
    started_on { Date.current }

    trait :payable do
      direction { :payable }
    end
  end
end
