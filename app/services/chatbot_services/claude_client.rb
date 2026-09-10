# frozen_string_literal: true

module ChatbotServices
  # Envia el mensaje del usuario + datos calculados a Claude, con el historial
  # reciente de la conversacion como contexto. No incluye supuestos/advertencias
  # en el prompt: esos ya vienen del calculador y se muestran aparte (CA10).
  class ClaudeClient
    SYSTEM_PROMPT = <<~PROMPT
      Eres el asesor financiero personal de Money Minder. Respondes en español,
      de forma breve y clara, usando unicamente los datos financieros que se
      te proporcionan. No inventes cifras que no esten en los datos. No agregues
      tu propia lista de supuestos o advertencias: esas se muestran por separado.
    PROMPT

    def initialize(client: nil)
      @client = client
    end

    def chat(user_message:, data:, context_messages: [])
      response = client.send_message(prompt: user_message, context: build_context(context_messages), data: data)

      return Result.failure(error: :claude_error, message: response[:error]) unless response[:success]

      Result.success(data: response[:content])
    rescue StandardError => e
      Rails.logger.error("[ChatbotServices::ClaudeClient] #{e.class}: #{e.message}")
      Result.failure(error: :claude_error, message: e.message)
    end

    private

    # Diferido a la primera llamada real: instanciar ClaudeService exige
    # ANTHROPIC_API_KEY, que no esta disponible en tests que stubean #chat.
    def client
      @client ||= ClaudeService.new
    end

    def build_context(context_messages)
      return SYSTEM_PROMPT if context_messages.blank?

      history = context_messages.map { |m| "#{m.role}: #{m.content}" }.join("\n")
      "#{SYSTEM_PROMPT}\nHistorial reciente de la conversacion:\n#{history}"
    end
  end
end
