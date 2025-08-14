FactoryBot.define do
  factory :ai_report do
    user { nil }
    report_type { nil }
    report_subtype { nil }
    reportable { nil }
    analysis_period_start { "2025-08-13" }
    analysis_period_end { "2025-08-13" }
    analysis_context { "MyText" }
    ai_request_data { "" }
    ai_response_data { "" }
    parsed_insights { "" }
    ai_model_used { "MyString" }
    tokens_used { "MyString" }
    processing_time { "9.99" }
    processing_success { false }
    error_message { "MyText" }
    expires_at { "2025-08-13 15:33:57" }
    metadata { "" }
  end
end
