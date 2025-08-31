# frozen_string_literal: true

# ReportsController
class ReportsController < ApplicationController
  before_action :set_report_filter, only: [:flow_chart, :distribution_chart, :main_data, :comparison_chart]

  def index
    @report_filter = ReportFilter.new()

    @budget_datasets = @report_filter.flow_dataset
    @earned_transaction_types_datasets = @report_filter.distribution_dataset("income")
    @spent_transaction_types_datasets = @report_filter.distribution_dataset("expense")
    @report_datasets = @report_filter.report_dataset
    @comparison_datasets = @report_filter.comparison_dataset

    # NUEVO: Obtener o generar reporte de IA financiero
    # @ai_financial_report = get_or_generate_ai_report
  end

  def flow_chart
    # Validar el filtro antes de procesar
    unless @report_filter.valid?
      Rails.logger.warn "Invalid report filter: #{@report_filter.errors.full_messages}"
      return
    end

    respond_to do |format|
      format.json do
        render json: {
          flowData: @report_filter.flow_dataset
        }
      end
    end
  end

  def distribution_chart
    # Validar el filtro antes de procesar
    unless @report_filter.valid?
      Rails.logger.warn "Invalid report filter: #{@report_filter.errors.full_messages}"
      return
    end

    respond_to do |format|
      format.json do
        render json: {
          distributionData: @report_filter.distribution_dataset(params.dig(:report, :filters, :transaction_type))
        }
      end
    end
  end

  def main_data
    # Validar el filtro antes de procesar
    unless @report_filter.valid?
      Rails.logger.warn "Invalid report filter: #{@report_filter.errors.full_messages}"
      return
    end

    respond_to do |format|
      format.json do
        render json: {
          reportData: @report_filter.report_dataset
        }
      end
    end
  end

  def comparison_chart
    # Validar el filtro antes de procesar
    unless @report_filter.valid?
      Rails.logger.warn "Invalid report filter: #{@report_filter.errors.full_messages}"
      return
    end

    respond_to do |format|
      format.json do
        render json: {
          comparisonData: @report_filter.comparison_dataset
        }
      end
    end
  end

  private

  def report_filter_params
    params.require(:report).permit(:id, filters: [:start_date, :end_date, :period, :budgets, :transaction_type])

    {
      start_date: params.dig(:report, :filters, :start_date),
      end_date: params.dig(:report, :filters, :end_date),
      period: params.dig(:report, :filters, :period) || 'monthly',
      budgets: params.dig(:report, :filters, :budgets) || []
    }
  end

  def set_report_filter
    @report_filter = ReportFilter.new(report_filter_params)
  end

  def get_or_generate_ai_report
    begin
      # Obtener el reporte más reciente o generar uno nuevo si está expirado
      report = AiReport.latest_or_generate(
        current_user.id,
        'general',
        'monthly'
      )

      # Log para debugging
      Rails.logger.info "AI Report loaded: #{report.uuid} (created: #{report.created_at})"

      report
    rescue => e
      Rails.logger.error "Error loading AI report: #{e.message}"

      # Crear un reporte vacío como fallback para que la vista no explote
      OpenStruct.new(
        insights: [],
        summary: {},
        processing_success: false,
        error_message: "Error cargando insights de IA: #{e.message}",
        created_at: Time.current,
        uuid: 'error-fallback'
      )
    end
  end
end
