# frozen_string_literal: true

# ReportsController
class ReportsController < ApplicationController
  def index
    @budget_datasets = Budget.flow_dataset
    @report_filter = ReportFilter.new(report_filter_params)

    # Si hay parámetros de filtro, generar los datos
    if filter_applied?
      generate_chart_data
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          labels: @labels,
          incomeData: @income_data,
          expenseData: @expense_data
        }
      end
    end
  end

  private

  def report_filter_params
    # Los parámetros vienen directamente en el root level
    {
      start_date: params[:start_date],
      end_date: params[:end_date],
      period: params[:period],
      budgets: params[:budgets],
      transaction_types: params[:transaction_types]
    }.compact # Remover valores nil
  end

  def filter_applied?
    params[:period].present? ||
    params[:start_date].present? ||
    params[:end_date].present? ||
    params[:budgets].present? ||
    params[:transaction_types].present?
  end

  def generate_chart_data
    # Validar el filtro antes de procesar
    unless @report_filter.valid?
      Rails.logger.warn "Invalid report filter: #{@report_filter.errors.full_messages}"
      return
    end

    # Generar datos usando el filtro
    @labels = @report_filter.labels_for_period
    @income_data = @report_filter.earned_per_frequency
    @expense_data = @report_filter.expensed_per_frequency

    Rails.logger.info "Generated data for period: #{@report_filter.period}, " \
                      "from #{@report_filter.start_date} to #{@report_filter.end_date}"
  end
end
