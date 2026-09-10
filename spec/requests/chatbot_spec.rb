# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/chatbot', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    allow_any_instance_of(ChatbotServices::ClaudeClient)
      .to receive(:chat).and_return(Result.success(data: 'Respuesta simulada'))
  end

  describe 'sin autenticacion' do
    it 'redirige al login en GET /chatbot' do
      get conversations_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'CA1: GET /chatbot' do
    before { sign_in user }

    it 'responde ok y muestra el historial de conversaciones previas' do
      conversation = create(:conversation, user:, title: 'Consulta previa')

      get conversations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Consulta previa')
      expect(conversation).to be_persisted
    end
  end

  describe 'CA8: POST /chatbot crea una conversacion independiente' do
    before { sign_in user }

    it 'crea un nuevo registro sin contaminar conversaciones existentes' do
      existing = create(:conversation, user:)
      create(:conversation_message, conversation: existing, content: 'mensaje viejo')

      expect { post conversations_path, params: { title: 'Nueva' } }.to change(Conversation, :count).by(1)

      new_conversation = user.conversations.order(created_at: :desc).first
      expect(new_conversation.messages).to be_empty
    end
  end

  describe 'CA9: GET /chatbot/:id retoma una conversacion previa' do
    before { sign_in user }

    it 'muestra los mensajes ordenados cronologicamente con su rol' do
      conversation = create(:conversation, user:)
      create(:conversation_message, conversation:, role: 'user', content: 'Primero')
      create(:conversation_message, conversation:, role: 'assistant', content: 'Segundo')

      get conversation_path(conversation)

      expect(response).to have_http_status(:ok)
      expect(response.body.index('Primero')).to be < response.body.index('Segundo')
    end

    it 'no permite acceder a una conversacion de otro usuario' do
      foreign_conversation = create(:conversation, user: other_user)

      get conversation_path(foreign_conversation)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /chatbot/:id/create_message' do
    before { sign_in user }

    let(:conversation) { create(:conversation, user:) }

    it 'CA2: crea el mensaje del usuario y la respuesta del asistente con contexto' do
      expect do
        post create_message_conversation_path(conversation), params: { content: '¿Cuánto dinero tengo disponible?' },
                                                             as: :turbo_stream
      end.to change(ConversationMessage, :count).by(2)

      expect(conversation.messages.last).to be_assistant
      expect(conversation.messages.last.content).to eq('Respuesta simulada')
    end

    it 'CA3: consulta de liquidez calcula datos sin necesidad de tarjetas o categorias previas' do
      make_budget(user:, type_code: 'cash', amount: 500, personal: true)

      post create_message_conversation_path(conversation), params: { content: '¿Cuánto dinero tengo disponible?' },
                                                           as: :turbo_stream

      assistant_message = conversation.messages.assistant.last
      expect(assistant_message.metadata['assumptions']).not_to be_empty
    end

    it 'CA10: la respuesta guarda supuestos y advertencias por separado del contenido' do
      post create_message_conversation_path(conversation), params: { content: '¿Cuánto dinero tengo disponible?' },
                                                           as: :turbo_stream

      assistant_message = conversation.messages.assistant.last
      expect(assistant_message.metadata).to include('assumptions', 'warnings')
    end

    it 'rechaza un mensaje vacio sin crear registros' do
      expect do
        post create_message_conversation_path(conversation), params: { content: '  ' }
      end.not_to change(ConversationMessage, :count)

      expect(response).to redirect_to(conversation_path(conversation))
    end

    it 'no permite enviar mensajes a una conversacion de otro usuario' do
      foreign_conversation = create(:conversation, user: other_user)

      post create_message_conversation_path(foreign_conversation), params: { content: 'hola' }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'CA5: gasto por categoria' do
    before { sign_in user }

    it 'agrupa transacciones de gasto por categoria del mes actual' do
      budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
      gastos = category_for('Gastos')
      restaurantes = category_for('Restaurantes', parent: gastos)
      make_transaction(user:, budget:, category: restaurantes, amount: 300, type_code: 'expense')
      conversation = create(:conversation, user:)
      content = '¿Cuánto gasté en restaurantes este mes?'

      post create_message_conversation_path(conversation), params: { content: }, as: :turbo_stream

      assistant_message = conversation.messages.assistant.last
      expect(assistant_message).to be_present
    end
  end

  describe 'CA6: estado de tarjeta' do
    before { sign_in user }

    it 'responde con el estado de la tarjeta encontrada por nombre' do
      make_credit_card(user:, name: 'Banamex Oro', limit_amount: 20_000)
      conversation = create(:conversation, user:)

      post create_message_conversation_path(conversation), params: { content: '¿En qué va mi ciclo de Banamex Oro?' },
                                                           as: :turbo_stream

      assistant_message = conversation.messages.assistant.last
      expect(assistant_message.metadata['warnings']).to eq([])
    end
  end

  describe 'CA7: escenario hipotetico' do
    before { sign_in user }

    it 'proyecta un escenario ajustado de reduccion de gasto' do
      budget = make_budget(user:, type_code: 'cash', amount: 1000, personal: true)
      gastos = category_for('Gastos')
      restaurantes = category_for('Restaurantes', parent: gastos)
      make_transaction(user:, budget:, category: restaurantes, amount: 1000, type_code: 'expense')
      conversation = create(:conversation, user:)

      post create_message_conversation_path(conversation), params: { content: '¿Y si recorto restaurantes 30%?' },
                                                           as: :turbo_stream

      assistant_message = conversation.messages.assistant.last
      expect(assistant_message.metadata['assumptions'].join).to match(/30%/)
    end
  end
end
