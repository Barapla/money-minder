# frozen_string_literal: true

# Conversation model — hilo de chat del chatbot financiero (FEAT-031).
class Conversation < ApplicationRecord
  MAX_MESSAGES = 100

  belongs_to :user
  has_many :messages, -> { order(created_at: :asc) }, class_name: 'ConversationMessage', dependent: :destroy

  validates :title, presence: true

  before_validation :generate_title, on: :create

  private

  def generate_title
    self.title ||= "Consulta del #{Date.current.strftime('%d/%m/%Y')}"
  end
end
