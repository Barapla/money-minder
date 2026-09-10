# frozen_string_literal: true

# Chatbot de analisis financiero con IA (FEAT-031). Solo lectura: nunca crea,
# actualiza o borra transacciones/presupuestos, unicamente Conversation/ConversationMessage.
class ChatbotController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversations, only: %i[index show]
  before_action :set_conversation, only: %i[show create_message]

  def index
    @conversation = @conversations.first
    @messages = @conversation&.messages || ConversationMessage.none
  end

  def show
    @messages = @conversation.messages
  end

  # Contenido de la burbuja de chat flotante (visible en cualquier pantalla): usa
  # siempre la conversacion mas reciente del usuario, creando una si no existe.
  def widget
    @conversation = current_user.conversations.order(created_at: :desc).first || current_user.conversations.create!
    @messages = @conversation.messages
  end

  def create
    conversation = current_user.conversations.create!(title: sanitized_title)
    redirect_to conversation_path(conversation)
  end

  def create_message
    content = params[:content].to_s.strip
    return redirect_to conversation_path(@conversation), alert: 'El mensaje no puede estar vacío' if content.blank?

    create_message_pair(content)
    respond_to_created_message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to conversation_path(@conversation), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def sanitized_title
    ActionController::Base.helpers.strip_tags(params[:title].to_s).strip.presence
  end

  # Transaccion: si build_assistant_message falla, el mensaje del usuario tampoco se persiste.
  def create_message_pair(content)
    ActiveRecord::Base.transaction do
      @user_message = @conversation.messages.create!(role: :user, content: content)
      @assistant_message = build_assistant_message(content)
    end
  end

  def respond_to_created_message
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to conversation_path(@conversation) }
    end
  end

  def build_assistant_message(content)
    result = ChatbotServices::QueryProcessor.new(user: current_user, conversation: @conversation,
                                                 user_message: content).process
    @conversation.messages.create!(
      role: :assistant,
      content: result.data[:content],
      metadata: { assumptions: result.data[:assumptions], warnings: result.data[:warnings] }
    )
  end

  def set_conversations
    @conversations = current_user.conversations.order(created_at: :desc)
  end

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end
end
