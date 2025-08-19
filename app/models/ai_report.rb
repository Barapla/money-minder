class AiReport < ApplicationRecord
  belongs_to :user
  belongs_to :report_type, class_name: 'Catalog', foreign_key: 'report_type_id'
  belongs_to :report_subtype, class_name: 'Catalog', foreign_key: 'report_subtype_id', optional: true
  belongs_to :reportable, polymorphic: true, optional: true

  # Callbacks
  before_save :parse_insights_from_response

  # Validaciones
  validates :report_type, presence: true
  validates :ai_response_data, presence: true, if: :processing_success?

  # Enums para tipos de reporte
  REPORT_TYPES = {
    'general' => 'Análisis Financiero General',
    'budget_specific' => 'Análisis de Presupuesto Específico',
    'spending_analysis' => 'Análisis de Gastos',
    'savings_progress' => 'Progreso de Ahorros',
    'credit_health' => 'Salud Crediticia',
    'cash_flow' => 'Flujo de Efectivo',
    'investment_advice' => 'Consejos de Inversión'
  }.freeze

  REPORT_SUBTYPES = {
    'monthly' => 'Mensual',
    'quarterly' => 'Trimestral',
    'annual' => 'Anual',
    'weekly' => 'Semanal',
    'custom_period' => 'Período Personalizado',
    'real_time' => 'Tiempo Real'
  }.freeze

  # Scopes
  scope :active, -> { where(active: true) }
  scope :successful, -> { where(processing_success: true) }
  scope :failed, -> { where(processing_success: false) }
  scope :by_type, ->(type) { where(report_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_period, ->(start_date, end_date) {
    where(analysis_period_start: start_date..end_date)
  }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  # Métodos de clase
  def self.latest_for_user_and_type(user_id, report_type_code, subtype = nil)
    report_type_catalog = Catalog.by_group_and_code('report_types', report_type_code)
    report_subtype_catalog = Catalog.by_group_and_code('report_subtypes', subtype) if subtype.present?
    return nil unless report_type_catalog

    query = active.successful.where(user_id: user_id, report_type: report_type_catalog)
    query = query.where(report_subtype: report_subtype_catalog) if subtype.present?
    latest_report = query.recent.first

    # Si no existe reporte o está expirado, generar uno nuevo
    if latest_report.nil? || latest_report.expired?
      latest_report = generate_new_report(user_id, report_type_code, subtype)
    end

    latest_report
  end

  def self.latest_or_generate(user_id, report_type, subtype = nil)
    # Alias más descriptivo para el método anterior
    latest_for_user_and_type(user_id, report_type, subtype)
  end

  def self.generate_new_report(user_id, report_type, subtype = nil)
    case report_type
    when 'general'
      AiReportService.create_financial_general_report(user_id)
    when 'budget_specific'
      # Para futuros reportes específicos por presupuesto
      # Necesitarías pasar el budget_id como parámetro adicional
      raise NotImplementedError, "Budget specific reports not implemented yet"
    when 'spending_analysis'
      # Para futuros análisis de gastos
      raise NotImplementedError, "Spending analysis reports not implemented yet"
    else
      raise ArgumentError, "Unknown report type: #{report_type}"
    end
  rescue => e
    Rails.logger.error "Error generating new AI report: #{e.message}"

    # Crear un reporte de error como fallback
    AiReport.create!(
      user_id: user_id,
      report_type: Catalog.by_group_and_code('report_types', report_type) ,
      report_subtype: Catalog.by_group_and_code('report_subtypes', subtype),
      analysis_period_start: Date.current.beginning_of_month,
      analysis_period_end: Date.current,
      analysis_context: "Error generating #{report_type} report",
      ai_request_data: { error_context: true },
      ai_response_data: { error: e.message },
      processing_success: false,
      error_message: e.message,
      metadata: { auto_generated: true, error_fallback: true }
    )
  end

  def self.cleanup_expired
    where('expires_at < ?', Time.current).update_all(active: false)
  end

  # Métodos de instancia
  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def insights
    return [] unless parsed_insights.present? && parsed_insights['insights'].present?
    parsed_insights['insights']
  end

  def summary
    return {} unless parsed_insights.present? && parsed_insights['summary'].present?
    parsed_insights['summary']
  end

  def high_priority_insights
    insights.select { |insight| insight['priority'] == 'high' }
  end

  def insights_by_type(type)
    insights.select { |insight| insight['type'] == type }
  end

  def processing_duration
    return nil unless processing_time.present?
    "#{processing_time}s"
  end

  def report_type_name
    REPORT_TYPES[report_type] || report_type.humanize
  end

  def report_subtype_name
    return nil unless report_subtype.present?
    REPORT_SUBTYPES[report_subtype] || report_subtype.humanize
  end

  def period_description
    return nil unless analysis_period_start.present?

    if analysis_period_end.present?
      "#{analysis_period_start.strftime('%d/%m/%Y')} - #{analysis_period_end.strftime('%d/%m/%Y')}"
    else
      analysis_period_start.strftime('%d/%m/%Y')
    end
  end

  def reportable_description
    return nil unless reportable.present?

    case reportable_type
    when 'Budget'
      "Presupuesto: #{reportable.name}"
    when 'User'
      "Usuario: #{reportable.email}"
    else
      "#{reportable_type}: #{reportable.try(:name) || reportable.id}"
    end
  end

  # Método para marcar como expirado
  def expire!
    update!(active: false, expires_at: Time.current)
  end

  # Método para regenerar reporte
  def regenerate!
    # Lógica para regenerar el reporte con los mismos parámetros
    # Esto se implementaría según tus necesidades específicas
  end

  private

  def parse_insights_from_response
    return unless ai_response_data.present? && processing_success?

    begin
      if ai_response_data.is_a?(Hash) && ai_response_data['content'].present?
        content = ai_response_data['content']

        # NUEVO: Extraer JSON de markdown code blocks
        if content.include?('```json')
          json_match = content.match(/```json\n(.*?)\n```/m)
          content = json_match[1] if json_match
        elsif content.include?('```')
          json_match = content.match(/```\n(.*?)\n```/m)
          content = json_match[1] if json_match
        end

        # Intentar parsear como JSON
        if content.strip.start_with?('{') || content.strip.start_with?('[')
          self.parsed_insights = JSON.parse(content.strip)
        else
          # Si no es JSON, crear estructura básica
          self.parsed_insights = {
            'insights' => [],
            'summary' => { 'raw_content' => content },
            'parsing_error' => 'Content is not valid JSON'
          }
        end
      end
    rescue JSON::ParserError => e
      self.parsed_insights = {
        'insights' => [],
        'summary' => {},
        'parsing_error' => e.message
      }
    end
  end
end
