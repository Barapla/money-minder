# frozen_string_literal: true

module Api
  module V1
    # GET  /api/v1/transactions?page=1&per_page=20&q=&transaction_type=&category=&start_date=&end_date=
    # GET  /api/v1/transactions/:id
    # POST /api/v1/transactions
    #   { transaction: { transaction_type_id, amount, description, category_id,
    #                    transaction_date, budget_id, icon_id, color_id } }
    #
    # Listado, detalle y alta de transacciones del usuario autenticado para la app movil.
    # Requiere header Authorization: Bearer <jwt> (Api::JwtAuthenticatable). Todas las
    # consultas se hacen a traves de current_api_user, por lo que los datos quedan
    # aislados por usuario.
    #
    # Filtros (opcionales, combinables):
    #   q                 texto en descripcion o nombre de categoria (sin distinguir mayusculas)
    #   transaction_type  code del catalogo (income | expense | transfer | refund)
    #   category          nombre exacto de la categoria
    #   start_date/end_date  rango de transaction_date (YYYY-MM-DD, inclusivo)
    #
    # Respuesta index (200):
    #   {
    #     "records": [
    #       { "id": 1, "date": "2026-09-10", "amount": 300.0, "currency": "MXN",
    #         "description": "Super", "category_name": "Comida", "transaction_type": "expense",
    #         "icon": "🛒", "color": "blue-500", "created_at": "...", "updated_at": "..." }
    #     ],
    #     "meta": { "current_page": 1, "total_pages": 3, "total_count": 45, "net_total": -1200.0 }
    #   }
    #
    # `meta.net_total` = ingresos - gastos de todas las transacciones que cumplen el filtro.
    # Respuesta show (200) / create (201): { "record": { ...mismos campos... } }
    # Error (404): { "error": { "code": "not_found", "message": "Recurso no encontrado" } }
    # Error (422): { "error": { "code": "validation_error", "message": "...", "details": {...} } }
    # Error (400): { "error": { "code": "invalid_date", "message": "..." } }
    # Error (401): { "errors": ["Token inválido o expirado"] }
    class TransactionsController < ApplicationController
      include Api::JwtAuthenticatable
      include PaginationHelper

      DEFAULT_PER_PAGE = 20

      rescue_from Date::Error, with: :render_invalid_date

      def index
        transactions = filtered_transactions.includes(:category, :currency, :transaction_type, :icon, :color)
                                            .order(transaction_date: :desc, created_at: :desc)
                                            .offset((page - 1) * per_page)
                                            .limit(per_page)

        render json: { records: transactions.map { |t| TransactionSerializer.new(t).as_json },
                       meta: pagination_meta }, status: :ok
      end

      def show
        transaction = current_api_user.transactions.find(params[:id])
        render json: { record: TransactionSerializer.new(transaction).as_json }, status: :ok
      end

      def create
        transaction = current_api_user.transactions.build(transaction_params)
        transaction.currency = current_api_user.currency || Currency.default
        return render_validation_errors(transaction) unless transaction.save

        render json: { record: TransactionSerializer.new(transaction).as_json }, status: :created
      end

      private

      def transaction_params
        params.require(:transaction).permit(:transaction_type_id, :amount, :description, :category_id,
                                            :transaction_date, :budget_id, :icon_id, :color_id)
      end

      # rubocop:disable Metrics/AbcSize -- un filtro opcional por linea
      def filtered_transactions
        @filtered_transactions ||= begin
          scope = current_api_user.transactions
          scope = scope.by_transaction_type(params[:transaction_type]) if params[:transaction_type].present?
          scope = scope.by_category(params[:category]) if params[:category].present?
          scope = scope.where(transaction_date: Date.iso8601(params[:start_date])..) if params[:start_date].present?
          scope = scope.where(transaction_date: ..Date.iso8601(params[:end_date])) if params[:end_date].present?
          scope = search(scope, params[:q]) if params[:q].present?
          scope
        end
      end
      # rubocop:enable Metrics/AbcSize

      def search(scope, query)
        term = "%#{ActiveRecord::Base.sanitize_sql_like(query.strip)}%"
        scope.left_joins(:category)
             .where('transactions.description ILIKE :term OR categories.name ILIKE :term', term:)
      end

      def pagination_meta
        { current_page: page, total_pages: total_pages(per_page, total_count), total_count:, net_total: }
      end

      def total_count
        @total_count ||= filtered_transactions.count
      end

      def net_total
        totals = filtered_transactions.joins(:transaction_type)
                                      .where(transaction_type: { code: %w[income expense] })
                                      .group('transaction_type.code').sum(:amount)
        (totals.fetch('income', 0) - totals.fetch('expense', 0)).to_f
      end

      def page
        value = params[:page].to_i
        value.positive? ? value : 1
      end

      def per_page
        value = params[:per_page].to_i
        value.positive? ? value : DEFAULT_PER_PAGE
      end

      def render_invalid_date
        render json: { error: { code: 'invalid_date', message: 'Fecha inválida. Usa el formato YYYY-MM-DD' } },
               status: :bad_request
      end
    end
  end
end
