# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AiReportGenerationJob do
  describe '.enqueue_once' do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(described_class).to receive(:perform_later)
    end

    it 'encola una sola generacion por usuario mientras dura el candado' do
      3.times { described_class.enqueue_once(1) }
      described_class.enqueue_once(2)

      expect(described_class).to have_received(:perform_later).with(1).once
      expect(described_class).to have_received(:perform_later).with(2).once
    end
  end

  describe '#perform' do
    it 'genera el reporte general del usuario' do
      allow(AiReportService).to receive(:create_financial_general_report)

      described_class.new.perform(7)

      expect(AiReportService).to have_received(:create_financial_general_report).with(7)
    end
  end
end
