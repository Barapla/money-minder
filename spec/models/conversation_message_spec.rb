# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationMessage, type: :model do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, user:) }

  it 'requiere content' do
    message = build(:conversation_message, conversation:, content: nil)
    expect(message).not_to be_valid
  end

  it 'expone role como enum user/assistant' do
    message = create(:conversation_message, conversation:, role: 'user')
    expect(message).to be_user
    expect(message).not_to be_assistant
  end

  it 'CA9: ordena los mensajes cronologicamente via conversation.messages' do
    older = create(:conversation_message, conversation:, content: 'primero', created_at: 2.hours.ago)
    newer = create(:conversation_message, conversation:, content: 'segundo', created_at: 1.hour.ago)

    expect(conversation.reload.messages.to_a).to eq([older, newer])
  end

  it 'rechaza un nuevo mensaje una vez alcanzado el limite de 100 por conversacion' do
    stub_const('Conversation::MAX_MESSAGES', 1)
    create(:conversation_message, conversation:)

    extra = build(:conversation_message, conversation:)
    expect(extra).not_to be_valid
    expect(extra.errors[:base]).to be_present
  end
end
