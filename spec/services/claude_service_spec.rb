# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClaudeService do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('test-key')
  end

  describe '#send_message' do
    it 'BUG-010: envia a Claude el mensaje del usuario junto con sus datos financieros reales' do
      response = instance_double(HTTParty::Response, code: 200,
                                                     parsed_response: {
                                                       'content' => [{ 'text' => 'Hola, tienes $500 disponibles.' }]
                                                     })
      sent_path = sent_body = nil
      allow(described_class).to receive(:post) do |path, options|
        sent_path = path
        sent_body = options[:body]
        response
      end

      result = described_class.new.send_message(prompt: 'hola', data: { primary_metric: 500 })

      expect(sent_path).to eq('/v1/messages')
      expect(sent_body).to include('hola')
      expect(sent_body).to include('primary_metric').and include('500')
      expect(result[:success]).to be true
      expect(result[:content]).to eq('Hola, tienes $500 disponibles.')
    end

    it 'BUG-010: retorna un error amigable en vez de levantar excepcion cuando la API de Claude falla' do
      response = instance_double(HTTParty::Response, code: 429, parsed_response: {})
      allow(described_class).to receive(:post).and_return(response)

      result = described_class.new.send_message(prompt: 'hola')

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Límite de rate exceeded')
    end
  end

  it 'exige ANTHROPIC_API_KEY configurada' do
    allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return(nil)

    expect { described_class.new }.to raise_error('ANTHROPIC_API_KEY no está configurada')
  end
end
