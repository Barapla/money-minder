# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/dashboard?period=month|30days|year
    #
    # Devuelve el dashboard financiero consolidado del usuario autenticado,
    # optimizado para consumo movil. Requiere header Authorization: Bearer <jwt>
    # (Api::JwtAuthenticatable). Todas las consultas se hacen a traves de
    # current_api_user, por lo que los datos quedan aislados por usuario.
    #
    # `period` (opcional, default "month"): rango de fechas para financial_summary.
    #   - month: mes calendario actual
    #   - 30days: ultimos 30 dias naturales desde hoy
    #   - year: año calendario actual
    #
    # Respuesta (200):
    #   {
    #     "record": {
    #       "financial_summary": {
    #         "total_income": 15000.0, "total_expenses": 8000.0, "balance": 7000.0,
    #         "month": 9, "year": 2026,
    #         "category_breakdown": [
    #           { "category_name": "Comida", "amount": 3000.0, "percentage": 37.5 }
    #         ]
    #       },
    #       "upcoming_payments": [
    #         { "id": 1, "description": "Renta", "amount": 5000.0,
    #           "payment_due_date": "2026-09-30", "days_until_due": 16,
    #           "category": "Vivienda" }
    #       ],
    #       "credit_cards": [
    #         { "id": 1, "name": "Tarjeta Oro", "calculated_balance": 2000.0,
    #           "cutting_date": "2026-09-25", "payment_due_date": "2026-09-30" }
    #       ],
    #       "latest_ai_insight": {
    #         "summary": { "raw_content" => "..." }, "generated_at": "2026-09-10T12:00:00Z",
    #         "report_type": "general"
    #       },
    #       "budgets_summary": {
    #         "total_budgeted": 12000.0, "total_spent": 4500.0,
    #         "percentage_used": 37.5, "active_count": 4
    #       }
    #     }
    #   }
    #
    # Error (401): { "errors": ["Token inválido o expirado"] }
    # Error (400): { "error": { "code": "invalid_period", "message": "Invalid period. Allowed: month, 30days, year" } }
    class DashboardController < ApplicationController
      include Api::JwtAuthenticatable

      ALLOWED_PERIODS = %w[month 30days year].freeze

      def show
        period = params[:period].presence || 'month'
        return render_invalid_period unless ALLOWED_PERIODS.include?(period)

        record = DashboardSerializer.new(current_api_user, date_range: date_range_for(period)).as_json
        render json: { record: record }, status: :ok
      end

      private

      def date_range_for(period)
        case period
        when '30days' then 30.days.ago.to_date..Date.current
        when 'year' then Date.current.beginning_of_year..Date.current.end_of_year
        else Date.current.beginning_of_month..Date.current.end_of_month
        end
      end

      def render_invalid_period
        render json: {
          error: { code: 'invalid_period', message: 'Invalid period. Allowed: month, 30days, year' }
        }, status: :bad_request
      end
    end
  end
end
