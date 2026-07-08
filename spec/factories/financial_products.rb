# frozen_string_literal: true

FactoryBot.define do
  factory :financial_product do
    sequence(:name) { |n| "Producto #{n}" }
    product_type { :debit }
    active { true }
    association :financial_institution
  end
end
