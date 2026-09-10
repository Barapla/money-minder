require 'rails_helper'

RSpec.describe AiReport, type: :model do
  describe '#parse_insights_from_response' do
    def find_or_create_report_catalog(group_code, code)
      Catalog.by_group_and_code(group_code, code) ||
        create(:catalog, group_catalog: create(:group_catalog, code: group_code), code:)
    end

    let(:user) { create(:user) }
    let(:report_type) { find_or_create_report_catalog('report_types', 'general') }

    it 'extrae insights aunque ai_response_data traiga symbol keys (formato de FinancialInsightsService)' do
      report = create(:ai_report, user:, report_type:, processing_success: true,
                                   ai_response_data: {
                                     success: true,
                                     insights: { 'critical_credit_actions' => [{ 'title' => 'Paga antes del corte' }] },
                                     format: 'json'
                                   })

      expect(report.insights).to eq([{ 'title' => 'Paga antes del corte' }])
    end

    it 'no explota si Claude devolvio texto crudo en insights (JSON no parseable)' do
      report = create(:ai_report, user:, report_type:, processing_success: true,
                                   ai_response_data: {
                                     success: true,
                                     insights: 'Respuesta con critical_credit_actions pero sin JSON valido',
                                     format: 'text',
                                     parsing_error: true
                                   })

      expect(report.insights).to eq([])
    end
  end
end
