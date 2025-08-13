class FinancialInsightsController < ApplicationController
  before_action :authenticate_user! # Asume que tienes autenticación

  def generate
    service = FinancialInsightsService.new(current_user.id)
    result = service.generate_insights

    if result[:success]
      # Intentar parsear la respuesta como JSON
      begin
        insights_data = JSON.parse(result[:content])
        render json: {
          success: true,
          insights: insights_data['insights'],
          summary: insights_data['summary'],
          usage: result[:usage]
        }
      rescue JSON::ParserError
        # Si no es JSON válido, devolver el texto plano
        render json: {
          success: true,
          raw_insights: result[:content],
          usage: result[:usage]
        }
      end
    else
      render json: {
        success: false,
        error: result[:error],
        details: result[:details]
      }, status: :unprocessable_entity
    end
  rescue => e
    render json: {
      error: 'Error generando insights',
      message: e.message
    }, status: :internal_server_error
  end

  # Endpoint para obtener datos sin análisis (debugging)
  def raw_data
    service = FinancialInsightsService.new(current_user.id)

    render json: {
      current_month: service.send(:get_current_month_data),
      previous_month: service.send(:get_previous_month_data),
      budgets: service.send(:get_active_budgets)
    }
  end
end
