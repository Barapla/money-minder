# frozen_string_literal: true

# ReportsController
class ReportsController < ApplicationController
  before_action :set_report_filter, only: [:flow_chart, :distribution_chart, :main_data]

  def index
    @report_filter = ReportFilter.new()

    @budget_datasets = @report_filter.flow_dataset
    @earned_transaction_types_datasets = @report_filter.distribution_dataset("income")
    @spent_transaction_types_datasets = @report_filter.distribution_dataset("expense")
    @report_datasets = @report_filter.report_dataset
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
end
