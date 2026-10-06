# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_message do
    role { 'user' }
    content { 'Mensaje de prueba' }
    association :conversation

    trait :assistant do
      role { 'assistant' }
      content { 'Respuesta de prueba' }
    end
  end
end
