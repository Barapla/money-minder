# frozen_string_literal: true

FactoryBot.define do
  factory :employment_information do
    association :user
    job_title { Faker::Job.title }
    start_date { Faker::Date.between(from: 5.years.ago, to: Date.current) }
    gross_salary_amount { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    calculation_periodicity { 'monthly_calculation' }
    payment_frequency { 'monthly_payment' }
  end
end
