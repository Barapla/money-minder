# frozen_string_literal: true

# FEAT-031: un turno (user/assistant) dentro de una Conversation.
class CreateConversationMessages < ActiveRecord::Migration[7.2]
  def change
    create_conversation_messages_table
    add_index :conversation_messages, :uuid, unique: true
    add_index :conversation_messages, %i[conversation_id created_at]
    add_foreign_key :conversation_messages, :conversations, name: 'fk_conversation_messages_conversation'
  end

  private

  def create_conversation_messages_table
    create_table :conversation_messages do |t|
      t.string :uuid, default: -> { 'gen_random_uuid()' }, null: false
      t.boolean :active, default: true
      t.bigint :conversation_id, null: false
      t.integer :role, null: false, default: 0
      t.text :content, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
