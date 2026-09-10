# frozen_string_literal: true

module ChatbotServices
  # Orquesta una consulta del chatbot: detecta el tipo de pregunta, delega el
  # calculo al servicio especializado y pide a Claude que redacte la respuesta
  # en lenguaje natural. Siempre retorna Result.success: si el calculador o
  # Claude fallan, cae a una respuesta textual construida a partir de los datos
  # calculados en vez de dejar al usuario sin respuesta.
  class QueryProcessor
    QUERY_PATTERNS = {
      liquidity: /liquidez|disponible|tengo/i,
      savings_projection: /ahorr(ar|ado|é)|proyecci[oó]n|para.*fecha/i,
      category_spending: /gast[eéo].*categor[ií]a|cu[aá]nto.*en/i,
      card_status: /ciclo|tarjeta|corte/i,
      scenario: /y si|escenario|recort[oa]/i
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
        advisor_context: payroll_context
      )
      content = claude_result.success? ? claude_result.data : fallback_content(data[:result])

      Result.success(data: { content: content, assumptions: data[:assumptions], warnings: data[:warnings] })
    end

    # Contexto de nomina/recordatorios (FEAT-007) para que el asesor pueda
    # referenciarlo aunque la consulta no sea explicitamente sobre nomina.
    def payroll_context
      info = DashboardPresenter.new(user).next_payroll_info
      return nil unless info

      "#{info[:next_period_label]}: #{info[:net_amount_formatted]} el #{info[:payment_date].strftime('%d/%m/%Y')} " \
        "(en #{info[:days_until]} días)."
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

    def fallback_content(result)
      lines = ["Resultado: #{result[:primary_metric]}"]
      result[:breakdown].each { |item| lines << "- #{item[:label]}: #{item[:amount]}" }
      lines.join("\n")
    end
  end
end
