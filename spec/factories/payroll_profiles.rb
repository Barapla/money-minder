# frozen_string_literal: true

FactoryBot.define do
  factory :payroll_profile do
    association :user
    monthly_gross_salary { 30_000.00 }
    base_salary { 30_000.00 }
    hire_date { 2.years.ago.to_date }
    savings_fund_percentage { 13.0 }
    savings_fund_rate { 4.0 }
    non_taxable_bonuses { {} }

    trait :new_employee do
      hire_date { 6.months.ago.to_date }
    end

    trait :veteran do
      hire_date { 5.years.ago.to_date }
    end

    trait :high_salary do
      monthly_gross_salary { 100_000.00 }
      base_salary { 100_000.00 }
      savings_fund_rate { 13.0 }
    end

    trait :with_bonuses do
      non_taxable_bonuses { { 'transporte' => 2000, 'vales' => 500 } }
    end

    trait :custom_rates do
      custom_isr_rate { 18.6 }
      custom_imss_rate { 3.0 }
    end
  end
end
