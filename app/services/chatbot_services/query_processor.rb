# frozen_string_literal: true

module ChatbotServices
  # Orquesta una consulta del chatbot: detecta el tipo de pregunta, delega el
  # calculo al servicio especializado y pide a Claude que redacte la respuesta
  # en lenguaje natural. Siempre retorna Result.success: si el calculador falla,
  # muestra su mensaje; si Claude falla, muestra un mensaje de error amigable
  # en vez de los datos crudos del calculador (ver BUG-010).
  class QueryProcessor
    include ActionView::Helpers::NumberHelper
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
        advisor_context: advisor_context
      )
      content = claude_result.success? ? claude_result.data : FAILURE_CONTENT

      Result.success(data: { content: content, assumptions: data[:assumptions], warnings: data[:warnings] })
    end

    def advisor_context
      [payroll_context, scheduled_reminders_context].compact.presence&.join("\n")
    end

    # Contexto de nomina (FEAT-007) para que el asesor pueda referenciarlo
    # aunque la consulta no sea explicitamente sobre nomina.
    def payroll_context
      info = DashboardPresenter.new(user).next_payroll_info
      return nil unless info

      "#{info[:next_period_label]}: #{info[:net_amount_formatted]} el #{info[:payment_date].strftime('%d/%m/%Y')} " \
        "(en #{info[:days_until]} días)."
    end

    # Recordatorios (ObligatoryPayment, tanto income como payment) programados
    # para el mes actual: lo que el usuario espera que le llegue vs. lo que
    # idealmente deberia gastar segun sus compromisos ya agendados.
    def scheduled_reminders_context
      summary = ChatbotServices::ScheduledRemindersSummary.new(user)
      income = summary.scheduled_income_total
      payment = summary.scheduled_payment_total
      return nil if income.zero? && payment.zero?

      'Recordatorios programados para este mes: ingresos programados ' \
        "#{number_to_currency(income, unit: '$')}, pagos programados (gasto ideal del mes) " \
        "#{number_to_currency(payment, unit: '$')}."
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
