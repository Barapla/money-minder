# frozen_string_literal: true

# ConversationMessage model — un turno (user/assistant) dentro de una Conversation (FEAT-031).
class ConversationMessage < ApplicationRecord
  belongs_to :conversation

  enum :role, { user: 0, assistant: 1 }

  validates :content, presence: true
  validate :conversation_message_limit_not_reached, on: :create

  private

  def conversation_message_limit_not_reached
    return unless conversation

    return if conversation.messages.count < Conversation::MAX_MESSAGES

    errors.add(:base, 'La conversación alcanzó el límite de 100 mensajes')
  end
end
