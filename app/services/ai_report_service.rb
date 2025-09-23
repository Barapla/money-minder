# frozen_string_literal: true

# AiReportService
class AiReportService
  def self.create_financial_general_report(user_id)
    start_time = Time.current

    # IMPORTANTE: NO llamar generate_insights desde aquí
    # Usar generate_insights_without_saving para evitar bucle
    insights_service = FinancialInsightsService.new(user_id)
    ai_result = insights_service.generate_insights_without_saving # <-- NUEVO MÉTODO

    processing_time = Time.current - start_time

    # Buscar los catálogos correctos
    report_type_catalog = Catalog.by_group_and_code('report_types', 'general')
    report_subtype_catalog = Catalog.by_group_and_code('report_subtypes', 'monthly')

    # Crear el reporte
    AiReport.create!(
      user_id:,
      report_type_id: report_type_catalog.id,
      report_subtype_id: report_subtype_catalog.id,
      analysis_period_start: Date.current.beginning_of_month,
      analysis_period_end: Date.current,
      analysis_context: 'Análisis financiero general mensual',
      ai_request_data: {
        service: 'FinancialInsightsService',
        user_id:,
        timestamp: start_time.iso8601
      },
      ai_response_data: ai_result,
      ai_model_used: 'claude-sonnet-4-20250514',
      tokens_used: (ai_result[:usage]&.dig('input_tokens')&.+ ai_result[:usage]&.dig('output_tokens')) || 0,
      processing_time:,
      processing_success: ai_result[:success],
      error_message: ai_result[:success] ? nil : ai_result[:error],
      expires_at: 1.day.from_now,
      metadata: {
        generated_by: 'financial_insights_service',
        version: '1.0'
      }
    )
  end

  def self.create_budget_specific_report(user_id, budget_id)
    # Para implementar en el futuro
    budget = Budget.find(budget_id)

    report_type_catalog = Catalog.by_group_and_code('report_types', 'budget_specific')
    report_subtype_catalog = Catalog.by_group_and_code('report_subtypes', 'monthly')

    AiReport.create!(
      user_id:,
      report_type_id: report_type_catalog.id,
      report_subtype_id: report_subtype_catalog.id,
      reportable: budget,
      analysis_period_start: Date.current.beginning_of_month,
      analysis_period_end: Date.current,
      analysis_context: "Análisis específico del presupuesto #{budget.name}",
      ai_request_data: { budget_id:, type: 'individual_analysis' },
      ai_response_data: { placeholder: 'To be implemented' },
      processing_success: false,
      error_message: 'Not implemented yet',
      metadata: { budget_name: budget.name, budget_type: budget.budget_type.code }
    )
  end
end
