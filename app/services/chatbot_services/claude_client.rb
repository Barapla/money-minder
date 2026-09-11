# frozen_string_literal: true

module ChatbotServices
  # Envia el mensaje del usuario + datos calculados a Claude, con el historial
  # reciente de la conversacion como contexto. No incluye supuestos/advertencias
  # en el prompt: esos ya vienen del calculador y se muestran aparte (CA10).
  class ClaudeClient
    SYSTEM_PROMPT = <<~PROMPT
      Eres el asesor financiero personal de Money Minder. Respondes en español, de forma
      breve, clara y con un tono cercano de asesor: no solo repites las cifras, tambien
      das una recomendacion practica y breve cuando sea util, considerando el contexto de
      nomina y recordatorios de pago si esta disponible. Usa unicamente los datos
      financieros que se te proporcionan. No inventes cifras que no esten en los datos.
      No agregues tu propia lista de supuestos o advertencias: esas se muestran por separado.
    PROMPT

    def initialize(client: nil)
      @client = client
    end

    def chat(user_message:, data:, context_messages: [], advisor_context: nil)
      context = build_context(context_messages, advisor_context)
      response = client.send_message(prompt: user_message, context: context, data: data)

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

    def build_context(context_messages, advisor_context)
      parts = [SYSTEM_PROMPT]
      parts << "Contexto de nómina y recordatorios del usuario:\n#{advisor_context}" if advisor_context.present?
      parts << "Historial reciente de la conversación:\n#{history_text(context_messages)}" if context_messages.present?
      parts.join("\n\n")
    end

    def history_text(context_messages)
      context_messages.map { |m| "#{m.role}: #{m.content}" }.join("\n")
    end
  end
end
