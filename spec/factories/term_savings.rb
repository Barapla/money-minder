# frozen_string_literal: true

FactoryBot.define do
  factory :term_saving do
    term_days { 90 }
    rate_locked { 0.12 }
    started_at { Date.current }
    principal_amount { 10_000 }
    status { :active }
    association :budget
  end
end
