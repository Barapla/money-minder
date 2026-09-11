# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::ClaudeClient, type: :service do
  let(:fake_claude_service) { instance_double(ClaudeService) }
  let(:client) { described_class.new(client: fake_claude_service) }

  it 'retorna Result.success con el contenido cuando Claude responde correctamente' do
    allow(fake_claude_service).to receive(:send_message).and_return(success: true, content: 'Tienes $1000 disponibles.')

    result = client.chat(user_message: '¿cuánto tengo?', data: { primary_metric: 1000 })

    expect(result).to be_success
    expect(result.data).to eq('Tienes $1000 disponibles.')
  end

  it 'retorna Result.failure cuando Claude responde con error' do
    allow(fake_claude_service).to receive(:send_message).and_return(success: false, error: 'API Key inválida')

    result = client.chat(user_message: '¿cuánto tengo?', data: {})

    expect(result).to be_failure
    expect(result.message).to eq('API Key inválida')
  end

  it 'retorna Result.failure si ClaudeService levanta una excepcion' do
    allow(fake_claude_service).to receive(:send_message).and_raise(StandardError, 'timeout')

    result = client.chat(user_message: '¿cuánto tengo?', data: {})

    expect(result).to be_failure
    expect(result.message).to eq('timeout')
  end

  it 'incluye el contexto de nomina cuando se proporciona' do
    allow(fake_claude_service).to receive(:send_message).and_return(success: true, content: 'ok')

    client.chat(user_message: 'siguiente', data: {},
                advisor_context: 'Próxima quincena: $1,000.00 el 15/09/2026 (en 5 días).')

    expect(fake_claude_service).to have_received(:send_message)
      .with(hash_including(context: a_string_matching(/Próxima quincena/)))
  end

  it 'incluye el historial reciente en el contexto enviado a Claude' do
    message = build_stubbed(:conversation_message, role: 'user', content: 'hola')
    allow(fake_claude_service).to receive(:send_message).and_return(success: true, content: 'ok')

    client.chat(user_message: 'siguiente', data: {}, context_messages: [message])

    expect(fake_claude_service).to have_received(:send_message)
      .with(hash_including(context: a_string_matching(/hola/)))
  end
end
