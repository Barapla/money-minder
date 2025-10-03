FactoryBot.define do
  factory :obligatory_payment do
    user { nil }
    name { "MyString" }
    amount { "9.99" }
    category { nil }
    description { "MyText" }
    color { nil }
    icon { nil }
  end
end
