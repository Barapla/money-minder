# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/calendar?month=YYYY-MM (default: mes actual)
    #
    # Respuesta (200):
    #   { "record": { "month": "2026-09",
    #                 "transactions": [ ...TransactionSerializer... ],
    #                 "reminders": [ { "id": 1, "name": "Renta", "amount": 5000.0, "date": "2026-09-01",
    #                                  "reminder_type": "payment", "category_name": "Vivienda", "icon": "🏘️" } ] } }
    # Error (400): { "error": { "code": "invalid_month", "message": "..." } }
    class CalendarController < ApplicationController
      include Api::JwtAuthenticatable

      def show
        month = parse_month(params[:month])
        return render_invalid_month unless month

        record = CalendarMonthSerializer.new(current_api_user, month:).as_json
        render json: { record: }, status: :ok
      end

      private

      def parse_month(value)
        return Date.current if value.blank?
        return nil unless value.to_s.match?(/\A\d{4}-\d{2}\z/)

        Date.strptime(value, '%Y-%m')
      rescue Date::Error
        nil
      end

      def render_invalid_month
        render json: { error: { code: 'invalid_month', message: 'Mes inválido. Usa el formato YYYY-MM' } },
               status: :bad_request
      end
    end
  end
end
