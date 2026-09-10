# frozen_string_literal: true

module ChatbotServices
  # Escenario hipotetico "y si recorto <categoria> <pct>%" (CA7). V1 solo soporta
  # reduccion porcentual sobre una categoria de gasto del mes actual, proyectada
  # a un horizonte fijo, comparada contra el escenario base sin cambios.
  class ScenarioSimulator
    DEFAULT_HORIZON_MONTHS = 6

    def initialize(user:, message:)
      @user = user
      @message = message.to_s
    end

    def calculate
      pct = extract_percentage
      keyword = extract_category_keyword
      matched_category, category_amount = matching_category(keyword)
      monthly_reduction = matched_category ? category_amount * (pct / 100.0) : 0.0

      Result.success(data: {
                       result: result_hash(pct, keyword, monthly_reduction),
                       assumptions: assumptions_for(pct),
                       warnings: warnings_for(matched_category, keyword)
                     })
    end

    private

    attr_reader :user, :message

    def result_hash(pct, keyword, monthly_reduction)
      base_projection = (current_liquidity + (base_net_flow * DEFAULT_HORIZON_MONTHS)).round(2)
      adjusted_projection = (base_projection + (monthly_reduction * DEFAULT_HORIZON_MONTHS)).round(2)
      breakdown = scenario_breakdown(pct, keyword, monthly_reduction, base_projection, adjusted_projection)
      { primary_metric: adjusted_projection, breakdown: breakdown }
    end

    def scenario_breakdown(pct, keyword, monthly_reduction, base_projection, adjusted_projection)
      reduction_label = "Reducción mensual estimada (#{keyword || 'categoría no identificada'} -#{pct.to_i}%)"
      [
        { label: 'Escenario base (sin cambios)', amount: base_projection },
        { label: reduction_label, amount: monthly_reduction.round(2) },
        { label: 'Escenario ajustado', amount: adjusted_projection },
        { label: 'Horizonte proyectado (meses)', amount: DEFAULT_HORIZON_MONTHS }
      ]
    end

    def assumptions_for(pct)
      reduction_note = "Se asume una reducción constante de #{pct.to_i}% en la categoría analizada " \
                        "durante #{DEFAULT_HORIZON_MONTHS} meses."
      [
        reduction_note,
        'El resto de ingresos y gastos se mantiene igual al comportamiento actual.',
        'V1 solo soporta reducciones porcentuales, no valores absolutos.'
      ]
    end

    def warnings_for(matched_category, keyword)
      return [] if matched_category

      ["No se encontró la categoría '#{keyword}' en tus gastos del mes actual; el escenario usa reducción $0."]
    end

    def base_net_flow
      ChatbotServices::NetFlowCalculator.new(user).monthly_net_flow
    end

    def current_liquidity
      LiquidityServices::Calculator.new(user).total_available_money.to_f
    end

    def extract_percentage
      match = message.match(/(\d+(\.\d+)?)\s*%/) || message.match(/(\d+(\.\d+)?)\s*por\s*ciento/i)
      match ? match[1].to_f : 10.0
    end

    def extract_category_keyword
      match = message.match(/(?:recort[eaoi]r?|reduc[ei]r?)\s+([a-záéíóúñ\s]+?)(?:\s+\d|\s+un\b|\s+en\b|$)/i)
      match && match[1].strip.downcase.presence
    end

    def matching_category(keyword)
      return [nil, 0.0] if keyword.blank?

      filter = ReportFilter.new(start_date: Date.current.beginning_of_month, end_date: Date.current.end_of_month,
                                user: user)
      totals = filter.categories('expense')
      name = totals.keys.find { |category_name| category_name.downcase.include?(keyword) }
      name ? [name, totals[name].to_f] : [nil, 0.0]
    end
  end
end
