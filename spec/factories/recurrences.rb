FactoryBot.define do
  factory :recurrence do
    recurrenceable_type { nil }
    recurrenceable_id { 1 }
    frequency_type { nil }
    frequency_value { 1 }
    day_of_week { 1 }
    day_of_month { 1 }
    month_of_year { 1 }
    start_date { "2025-09-24" }
    end_date { "2025-09-24" }
  end
end
