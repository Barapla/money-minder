# frozen_string_literal: true

# FEAT-031: hilo de chat del chatbot de analisis financiero con IA.
class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.string :uuid, default: -> { 'gen_random_uuid()' }, null: false
      t.boolean :active, default: true
      t.bigint :user_id, null: false
      t.string :title, null: false

      t.timestamps
    end

    add_index :conversations, :uuid, unique: true
    add_index :conversations, %i[user_id created_at]
    add_foreign_key :conversations, :users, name: 'fk_conversations_user'
  end
end
