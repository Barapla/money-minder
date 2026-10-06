# frozen_string_literal: true

module Api
  module V1
    # GET  /api/v1/obligatory_payments?reminder_type=payment|income
    # POST /api/v1/obligatory_payments
    #   { obligatory_payment: { name, amount, reminder_type, category_id, icon_id, color_id,
    #                           description, due_date,                      # recordatorio unico
    #                           recurrence: { frequency_type_id, frequency_value, start_date, end_date } } }
    #
    # Sin `recurrence` el recordatorio es unico y requiere `due_date` (igual que el web).
    class ObligatoryPaymentsController < ApplicationController
      include Api::JwtAuthenticatable

      def index
        payments = current_api_user.obligatory_payments
                                   .includes(:category, :color, :icon, recurrence: :frequency_type)
                                   .by_type(params[:reminder_type])
                                   .map { |p| ObligatoryPaymentSerializer.new(p).as_json }
        # Primero los que tienen proxima fecha (mas cercana primero); los vencidos sin fecha al final.
        payments.sort_by! { |p| [p[:next_due_date] ? 0 : 1, p[:next_due_date] || Date.current] }

        render json: { records: payments }, status: :ok
      end

      def create
        payment = current_api_user.obligatory_payments.build(payment_params)
        build_recurrence(payment)
        return render_validation_errors(payment) unless payment.save

        render json: { record: ObligatoryPaymentSerializer.new(payment).as_json }, status: :created
      end

      private

      def payment_params
        params.require(:obligatory_payment)
              .permit(:name, :amount, :reminder_type, :category_id, :icon_id, :color_id, :description, :due_date)
      end

      def build_recurrence(payment)
        attrs = params.dig(:obligatory_payment, :recurrence)
        return if attrs.blank?

        payment.due_date = nil
        payment.build_recurrence(
          attrs.permit(:frequency_type_id, :frequency_value, :start_date, :end_date)
               .merge(recurrenceable_type_id: recurrenceable_type_id)
        )
      end

      def recurrenceable_type_id
        Catalog.by_group_and_code('recurrenceable_types', 'obligatory_payment')&.id
      end
    end
  end
end
