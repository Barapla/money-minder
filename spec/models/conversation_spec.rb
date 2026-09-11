# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversation, type: :model do
  let(:user) { create(:user) }

  it 'pertenece a un usuario' do
    conversation = create(:conversation, user:)
    expect(conversation.user).to eq(user)
  end

  it 'genera un titulo automaticamente si no se provee' do
    conversation = Conversation.create!(user:, title: nil)
    expect(conversation.title).to be_present
  end

  it 'respeta un titulo explicito' do
    conversation = Conversation.create!(user:, title: 'Mi consulta')
    expect(conversation.title).to eq('Mi consulta')
  end

  it 'destruye sus mensajes al ser destruida (CA8 aislamiento de conversaciones)' do
    conversation = create(:conversation, user:)
    create(:conversation_message, conversation:)
    expect { conversation.destroy }.to change(ConversationMessage, :count).by(-1)
  end

  it 'CA8: dos conversaciones del mismo usuario mantienen mensajes independientes' do
    conversation_a = create(:conversation, user:)
    conversation_b = create(:conversation, user:)
    create(:conversation_message, conversation: conversation_a, content: 'Hola A')

    expect(conversation_a.messages.count).to eq(1)
    expect(conversation_b.messages.count).to eq(0)
  end
end
