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
    #       "trend_data": [
    #         { "month": "2026-04", "income": 15000.0, "expenses": 9000.0, "balance": 6000.0 }
    #       ],
    #       "upcoming_payments": [
    #         { "id": 1, "title": "Renta", "amount": 5000.0, "currency": "MXN",
    #           "due_date": "2026-09-30", "days_until_due": 16, "category": "Vivienda" }
    #       ],
    #       "active_budgets": [
    #         { "budget_id": 1, "category_name": "Comida", "category_color": "Purple",
    #           "budgeted_amount": 2000.0, "spent_amount": 800.0, "remaining_amount": 1200.0,
    #           "percentage_used": 40.0 }
    #       ],
    #       "credit_cards_summary": [
    #         { "card_id": 1, "card_name": "Tarjeta Oro", "current_balance": 2000.0,
    #           "credit_limit": 10000.0, "available_credit": 8000.0,
    #           "next_cutting_date": "2026-09-25", "next_payment_date": "2026-09-30" }
    #       ],
    #       "savings_summary": [
    #         { "fund_id": 1, "fund_name": "Fondo Emergencia", "current_amount": 5000.0,
    #           "goal_amount": 20000.0, "percentage_achieved": 25.0 }
    #       ],
    #       "recent_transactions": [
    #         { "id": 1, "description": "Super", "amount": 500.0, "currency": "MXN",
    #           "transaction_date": "2026-09-14", "category_name": "Comida",
    #           "category_color": "Purple", "transaction_type": "expense" }
    #       ],
    #       "latest_insight": {
    #         "id": 1, "content": { "raw_content" => "..." },
    #         "created_at": "2026-09-10T12:00:00Z", "expires_at": null
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
