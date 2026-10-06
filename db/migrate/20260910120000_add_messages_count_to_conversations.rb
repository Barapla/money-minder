# frozen_string_literal: true

# FEAT-031: counter_cache para evitar un COUNT query en cada validacion de limite de mensajes.
class AddMessagesCountToConversations < ActiveRecord::Migration[7.2]
  def up
    add_column :conversations, :messages_count, :integer, null: false, default: 0
    execute <<~SQL.squish
      UPDATE conversations
      SET messages_count = (
        SELECT COUNT(*) FROM conversation_messages WHERE conversation_messages.conversation_id = conversations.id
      )
    SQL
  end

  def down
    remove_column :conversations, :messages_count
  end
end
