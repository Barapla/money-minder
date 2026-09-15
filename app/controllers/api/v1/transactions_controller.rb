# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/transactions?page=1&per_page=20
    # GET /api/v1/transactions/:id
    #
    # Listado y detalle de transacciones del usuario autenticado para la app movil.
    # Requiere header Authorization: Bearer <jwt> (Api::JwtAuthenticatable). Todas las
    # consultas se hacen a traves de current_api_user, por lo que los datos quedan
    # aislados por usuario.
    #
    # Respuesta index (200):
    #   {
    #     "records": [
    #       { "id": 1, "date": "2026-09-10", "amount": 300.0, "currency": "MXN",
    #         "description": "Super", "category_name": "Comida", "transaction_type": "expense",
    #         "created_at": "...", "updated_at": "..." }
    #     ],
    #     "meta": { "current_page": 1, "total_pages": 3, "total_count": 45 }
    #   }
    #
    # Respuesta show (200): { "record": { ...mismos campos... } }
    # Error (404): { "error": { "code": "not_found", "message": "Recurso no encontrado" } }
    # Error (401): { "errors": ["Token inválido o expirado"] }
    class TransactionsController < ApplicationController
      include Api::JwtAuthenticatable
      include PaginationHelper

      DEFAULT_PER_PAGE = 20

      def index
        transactions = scoped_transactions.order(transaction_date: :desc)
                                          .offset((page - 1) * per_page)
                                          .limit(per_page)

        render json: { records: transactions.map { |t| TransactionSerializer.new(t).as_json },
                       meta: pagination_meta }, status: :ok
      end

      def show
        transaction = scoped_transactions.find(params[:id])
        render json: { record: TransactionSerializer.new(transaction).as_json }, status: :ok
      end

      private

      def scoped_transactions
        current_api_user.transactions.includes(:category, :currency, :transaction_type)
      end

      def pagination_meta
        { current_page: page, total_pages: total_pages(per_page, total_count), total_count: total_count }
      end

      def total_count
        @total_count ||= current_api_user.transactions.count
      end

      def page
        value = params[:page].to_i
        value.positive? ? value : 1
      end

      def per_page
        value = params[:per_page].to_i
        value.positive? ? value : DEFAULT_PER_PAGE
      end
    end
  end
end
