# frozen_string_literal: true

# Genera el reporte IA general de un usuario fuera del request. La generacion
# llama a la API de Claude y tarda ~1 minuto, demasiado para el dashboard movil.
class AiReportGenerationJob < ApplicationJob
  queue_as :default

  LOCK_TTL = 15.minutes

  # Encola a lo mucho una generacion por usuario cada LOCK_TTL.
  def self.enqueue_once(user_id)
    return unless Rails.cache.write("ai_report_generation/#{user_id}", true, expires_in: LOCK_TTL, unless_exist: true)

    perform_later(user_id)
  end

  def perform(user_id)
    AiReportService.create_financial_general_report(user_id)
  end
end
