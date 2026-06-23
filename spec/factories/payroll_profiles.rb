# frozen_string_literal: true

FactoryBot.define do
  factory :payroll_profile do
    association :user
    monthly_gross_salary { 30_000.00 }
    hire_date { 2.years.ago.to_date }
    savings_fund_percentage { 13.0 }

    trait :new_employee do
      hire_date { 6.months.ago.to_date }
    end

    trait :veteran do
      hire_date { 5.years.ago.to_date }
    end

    trait :high_salary do
      monthly_gross_salary { 100_000.00 }
    end
  end
end
