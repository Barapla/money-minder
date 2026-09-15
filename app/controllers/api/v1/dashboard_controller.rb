# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/dashboard
    #
    # Devuelve el dashboard financiero consolidado del usuario autenticado,
    # optimizado para consumo movil. Requiere header Authorization: Bearer <jwt>
    # (Api::JwtAuthenticatable). Todas las consultas se hacen a traves de
    # current_api_user, por lo que los datos quedan aislados por usuario.
    #
    # Respuesta (200):
    #   {
    #     "record": {
    #       "financial_summary": {
    #         "total_income": 15000.0, "total_expenses": 8000.0, "balance": 7000.0,
    #         "month": 9, "year": 2026
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
    class DashboardController < ApplicationController
      include Api::JwtAuthenticatable

      def show
        render json: { record: DashboardSerializer.new(current_api_user).as_json }, status: :ok
      end
    end
  end
end
