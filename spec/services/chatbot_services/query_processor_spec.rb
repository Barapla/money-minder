# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatbotServices::QueryProcessor, type: :service do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, user:) }

  def stub_claude(content: 'Respuesta generada', success: true, message: nil)
    fake_client = instance_double(ChatbotServices::ClaudeClient)
    result = success ? Result.success(data: content) : Result.failure(error: :claude_error, message: message)
    allow(fake_client).to receive(:chat).and_return(result)
    allow(ChatbotServices::ClaudeClient).to receive(:new).and_return(fake_client)
    fake_client
  end

  it 'CA2: detecta el tipo de consulta y delega al calculador correspondiente' do
    stub_claude
    liquidity_result = Result.success(data: { result: { primary_metric: 100, breakdown: [] }, assumptions: [],
                                              warnings: [] })
    allow_any_instance_of(ChatbotServices::LiquidityCalculator).to receive(:calculate).and_return(liquidity_result)

    processor = described_class.new(user:, conversation:, user_message: '¿Cuánto dinero tengo disponible?')
    result = processor.process

    expect(result).to be_success
    expect(result.data[:content]).to eq('Respuesta generada')
  end

  it 'usa la respuesta del calculador directamente cuando este falla (sin llamar a Claude)' do
    fake_client = stub_claude
    allow_any_instance_of(ChatbotServices::CardStatusChecker).to receive(:calculate)
      .and_return(Result.failure(error: :card_not_found, message: 'No encontramos la tarjeta'))

    processor = described_class.new(user:, conversation:, user_message: '¿En qué va mi ciclo de tarjeta?')
    result = processor.process

    expect(result.data[:content]).to eq('No encontramos la tarjeta')
    expect(fake_client).not_to have_received(:chat)
  end

  it 'cae a una respuesta textual construida con los datos cuando Claude falla' do
    stub_claude(success: false, message: 'Límite de rate exceeded')
    liquidity_result = Result.success(
      data: {
        result: { primary_metric: 500, breakdown: [{ label: 'Efectivo', amount: 500 }] },
        assumptions: [], warnings: []
      }
    )
    allow_any_instance_of(ChatbotServices::LiquidityCalculator).to receive(:calculate).and_return(liquidity_result)

    processor = described_class.new(user:, conversation:, user_message: '¿Cuánto tengo disponible?')
    result = processor.process

    expect(result).to be_success
    expect(result.data[:content]).to include('500')
  end

  it 'incluye el contexto de nomina en la llamada a Claude cuando el usuario la tiene configurada' do
    create(:employment_information, user:, payment_frequency: 'monthly_payment', start_date: 10.days.ago.to_date)
    received_advisor_context = nil
    fake_client = instance_double(ChatbotServices::ClaudeClient)
    allow(fake_client).to receive(:chat) do |advisor_context:, **|
      received_advisor_context = advisor_context
      Result.success(data: 'ok')
    end
    allow(ChatbotServices::ClaudeClient).to receive(:new).and_return(fake_client)
    allow_any_instance_of(ChatbotServices::LiquidityCalculator).to receive(:calculate)
      .and_return(Result.success(data: { result: { primary_metric: 0, breakdown: [] }, assumptions: [], warnings: [] }))

    described_class.new(user:, conversation:, user_message: '¿Cuánto tengo disponible?').process

    expect(received_advisor_context).to be_present
  end

  it 'cae a un mensaje de error generico si el calculador lanza una excepcion inesperada' do
    stub_claude
    allow_any_instance_of(ChatbotServices::LiquidityCalculator).to receive(:calculate).and_raise(StandardError, 'boom')

    processor = described_class.new(user:, conversation:, user_message: '¿Cuánto dinero tengo disponible?')
    result = processor.process

    expect(result).to be_success
    expect(result.data[:content]).to match(/no pudimos procesar/i)
  end

  it 'CA2: envia solo los ultimos 10 mensajes de contexto a Claude' do
    12.times { |i| create(:conversation_message, conversation:, content: "mensaje #{i}") }
    received_context = nil
    fake_client = instance_double(ChatbotServices::ClaudeClient)
    allow(fake_client).to receive(:chat) do |context_messages:, **|
      received_context = context_messages
      Result.success(data: 'ok')
    end
    allow(ChatbotServices::ClaudeClient).to receive(:new).and_return(fake_client)
    allow_any_instance_of(ChatbotServices::LiquidityCalculator).to receive(:calculate)
      .and_return(Result.success(data: { result: { primary_metric: 0, breakdown: [] }, assumptions: [], warnings: [] }))

    described_class.new(user:, conversation:, user_message: '¿Cuánto tengo disponible?').process

    expect(received_context.size).to eq(10)
  end
end
