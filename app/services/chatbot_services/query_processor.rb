# frozen_string_literal: true

module ChatbotServices
  # Orquesta una consulta del chatbot: detecta el tipo de pregunta, delega el
  # calculo al servicio especializado y pide a Claude que redacte la respuesta
  # en lenguaje natural. Siempre retorna Result.success: si el calculador falla,
  # muestra su mensaje; si Claude falla, muestra un mensaje de error amigable
  # en vez de los datos crudos del calculador (ver BUG-010).
  class QueryProcessor
    include ActionView::Helpers::NumberHelper
    # Orden por especificidad: gana el primero que case. Todos anclados con \b
    # porque sin ancla /cu[aá]nto.*en/ casaba con "cuanto ... idEALMENte" y
    # mandaba una pregunta de proyeccion al analizador de categorias.
    QUERY_PATTERNS = {
      card_status: /\b(ciclo|corte|utilizaci[oó]n|tarjeta de cr[eé]dito)\b/i,
      scenario: /\b(y si|qu[eé] pasa si|escenario|simula|recort[aeo])\b/i,
      savings_projection: /\b(proyecci[oó]n(es)?|proyectar|acumulad[oa]|acumular|tendr[íi]?a|
                            aguinaldo|fin de a[nñ]o|ahorr(ar|ado|é))\b|
                           \b(hasta|para) el \d{1,2}\b/ix,
      category_spending: /\bcu[aá]nto\s+\w*\s*(gast|llev)\w*/i,
      liquidity: /\b(liquidez|disponible|cu[aá]nto tengo|dispongo)\b/i
    }.freeze

    FAILURE_CONTENT = 'No pudimos procesar tu consulta en este momento. Intenta reformularla en unos minutos.'

    def initialize(user:, conversation:, user_message:)
      @user = user
      @conversation = conversation
      @user_message = user_message
    end

    def process
      calc_result = calculator_for(detect_query_type).calculate
      return calculator_failure_response(calc_result) if calc_result.failure?

      claude_response(calc_result.data)
    rescue StandardError => e
      Rails.logger.error("[ChatbotServices::QueryProcessor] #{e.class}: #{e.message}")
      Result.success(data: { content: FAILURE_CONTENT, assumptions: [], warnings: [] })
    end

    private

    attr_reader :user, :conversation, :user_message

    def calculator_failure_response(calc_result)
      Result.success(data: { content: calc_result.message, assumptions: [], warnings: [] })
    end

    def claude_response(data)
      claude_result = ChatbotServices::ClaudeClient.new.chat(
        user_message: user_message, data: data[:result], context_messages: context_messages,
        advisor_context: advisor_context
      )
      content = claude_result.success? ? claude_result.data : FAILURE_CONTENT

      Result.success(data: { content: content, assumptions: data[:assumptions], warnings: data[:warnings] })
    end

    # La misma foto en TODA consulta, sin importar el calculador que haya tocado:
    # saldos, nomina proyectada, aguinaldo y fondo de ahorro, y recordatorios.
    # Antes cada calculador mandaba su propia base y dos respuestas seguidas se
    # contradecian en el patrimonio; la nomina no llegaba nunca.
    def advisor_context
      ChatbotServices::FinancialSnapshot.new(user, horizon_date: horizon_date).to_prompt.presence
    end

    def horizon_date
      @horizon_date ||= ChatbotServices::HorizonParser.call(user_message) || Date.current.end_of_year
    end

    def detect_query_type
      QUERY_PATTERNS.find { |_type, pattern| user_message =~ pattern }&.first || :liquidity
    end

    def calculator_for(query_type)
      case query_type
      when :savings_projection then ChatbotServices::SavingsProjector.new(user: user, message: user_message)
      when :category_spending then ChatbotServices::CategoryAnalyzer.new(user: user)
      when :card_status then ChatbotServices::CardStatusChecker.new(user: user, message: user_message)
      when :scenario then ChatbotServices::ScenarioSimulator.new(user: user, message: user_message)
      else ChatbotServices::LiquidityCalculator.new(user: user)
      end
    end

    def context_messages
      conversation.messages.order(created_at: :desc).limit(10).to_a.reverse
    end
  end
end
