FactoryBot.define do
  factory :group_catalog do
    # sequence: genera valores únicos automáticamente
    sequence(:name) { |n| "#{Faker::Commerce.department} #{n}" }
    sequence(:code) { |n| "#{Faker::Alphanumeric.alpha(number: 10).upcase}_#{n}" }
    
    # Valores por defecto
    active { true }
    
    # Traits: variaciones de la factory
    trait :inactive do
      active { false }
    end
    
    trait :account_types do
      name { "Account Types" }
      code { "ACCOUNT_TYPES" }
    end
    
    trait :transaction_types do
      name { "Transaction Types" }
      code { "TRANSACTION_TYPES" }
    end
  end
end