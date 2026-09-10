# frozen_string_literal: true

# ReportsController
class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_report_filter, only: %i[flow_chart distribution_chart main_data comparison_chart]

  def index
    @report_filter = ReportFilter.new(user: current_user)

    @budget_datasets = @report_filter.flow_dataset
    @earned_transaction_types_datasets = @report_filter.distribution_dataset('income')
    @spent_transaction_types_datasets = @report_filter.distribution_dataset('expense')
    @report_datasets = @report_filter.report_dataset
    @comparison_datasets = @report_filter.comparison_dataset
    @ai_financial_report = AiReport.latest_for_user_and_type(current_user.id, 'general')
  end

  def flow_chart
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
    params.require(:report).permit(:id, filters: %i[start_date end_date period budgets transaction_type])

    {
      start_date: params.dig(:report, :filters, :start_date),
      end_date: params.dig(:report, :filters, :end_date),
      period: params.dig(:report, :filters, :period) || 'monthly',
      budgets: params.dig(:report, :filters, :budgets) || []
    }
  end

  def set_report_filter
    @report_filter = ReportFilter.new(report_filter_params.merge(user: current_user))
  end
end
