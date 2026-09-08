# frozen_string_literal: true

# module ApplicationHelper
module ApplicationHelper
  include ColorHelper
  include SvgHelper
  include DayDetailsHelper

  # Instituciones disponibles para un tipo de instrumento (FEAT-026), mas la opcion "Otro"
  # para ingreso manual cuando el producto no esta en el catalogo.
  def financial_institutions_for_select(product_type)
    institutions = FinancialCatalogServices::Registry.by_type(product_type).map(&:institution).uniq.sort

    institutions.map { |institution| [institution, institution] } + [%w[Otro other]]
  end

  # Productos del catalogo para una institucion y tipo de instrumento dados (FEAT-026).
  def financial_products_for_select(product_type, institution)
    return [] if institution.blank? || institution == 'other'

    FinancialCatalogServices::Registry.by_type(product_type)
                                      .by_institution(institution)
                                      .map { |product| [product.name, product.id] }
  end

  # Institucion a precargar en el select del formulario (FEAT-026): la del producto
  # asociado si existe, "other" si el instrumento ya existe sin producto, o nil si es nuevo.
  def selected_financial_institution(financial_product_id:, persisted:)
    return 'other' if financial_product_id.blank? && persisted
    return nil if financial_product_id.blank?

    FinancialCatalogServices::Registry.find_by_id(financial_product_id)&.institution
  end

  def ai_report_status_badge(report)
    if report.processing_success?
      content_tag :span, '✓ Actualizado', class: 'badge badge-success'
    else
      content_tag :span, '⚠ Error', class: 'badge badge-danger'
    end
  end

  def ai_report_freshness(report)
    return 'Error' unless report.created_at

    time_ago = time_ago_in_words(report.created_at)

    if report.created_at > 1.hour.ago
      content_tag :span, "Hace #{time_ago}", class: 'text-success'
    elsif report.created_at > 1.day.ago
      content_tag :span, "Hace #{time_ago}", class: 'text-warning'
    else
      content_tag :span, "Hace #{time_ago}", class: 'text-danger'
    end
  end

  def priority_badge(priority)
    case priority
    when 'urgent'
      content_tag :span, '🔴 Urgente', class: 'badge badge-danger'
    when 'high'
      content_tag :span, '🟠 Alta', class: 'badge badge-danger'
    when 'medium'
      content_tag :span, '🟡 Media', class: 'badge badge-warning'
    when 'low'
      content_tag :span, '🟢 Baja', class: 'badge badge-info'
    else
      content_tag :span, priority, class: 'badge badge-secondary'
    end
  end

  def insight_type_icon(type)
    case type
    when 'alert'
      '🚨'
    when 'warning'
      '⚠️'
    when 'success'
      '✅'
    when 'info'
      'ℹ️'
    else
      '📊'
    end
  end

  def get_insight_card_styles(type, priority)
    # Mapear tipo de insight a colores
    base_styles = case type
                  when 'cutting_date_urgent'
                    {
                      bg: 'bg-red-500/10',
                      border: 'border-red-500/20',
                      icon_bg: 'bg-red-500/20',
                      title_color: 'text-red-300',
                      action_color: 'text-red-200',
                      accent_border: 'border-red-500/30',
                      icon: '<svg class="w-4 h-4 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
                    }
                  when 'payment_optimization'
                    {
                      bg: 'bg-blue-500/10',
                      border: 'border-blue-500/20',
                      icon_bg: 'bg-blue-500/20',
                      title_color: 'text-blue-300',
                      action_color: 'text-blue-200',
                      accent_border: 'border-blue-500/30',
                      icon: '<svg class="w-4 h-4 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"></path></svg>'
                    }
                  when 'utilization_critical'
                    {
                      bg: 'bg-amber-500/10',
                      border: 'border-amber-500/20',
                      icon_bg: 'bg-amber-500/20',
                      title_color: 'text-amber-300',
                      action_color: 'text-amber-200',
                      accent_border: 'border-amber-500/30',
                      icon: '<svg class="w-4 h-4 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"></path></svg>'
                    }
                  when 'score_opportunity'
                    {
                      bg: 'bg-emerald-500/10',
                      border: 'border-emerald-500/20',
                      icon_bg: 'bg-emerald-500/20',
                      title_color: 'text-emerald-300',
                      action_color: 'text-emerald-200',
                      accent_border: 'border-emerald-500/30',
                      icon: '<svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>'
                    }
                  when 'alert'
                    {
                      bg: 'bg-red-500/10',
                      border: 'border-red-500/20',
                      icon_bg: 'bg-red-500/20',
                      title_color: 'text-red-300',
                      action_color: 'text-red-200',
                      accent_border: 'border-red-500/30',
                      icon: '<svg class="w-4 h-4 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.464 0L4.35 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>'
                    }
                  when 'warning'
                    {
                      bg: 'bg-amber-500/10',
                      border: 'border-amber-500/20',
                      icon_bg: 'bg-amber-500/20',
                      title_color: 'text-amber-300',
                      action_color: 'text-amber-200',
                      accent_border: 'border-amber-500/30',
                      icon: '<svg class="w-4 h-4 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.464 0L4.35 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>'
                    }
                  when 'success'
                    {
                      bg: 'bg-emerald-500/10',
                      border: 'border-emerald-500/20',
                      icon_bg: 'bg-emerald-500/20',
                      title_color: 'text-emerald-300',
                      action_color: 'text-emerald-200',
                      accent_border: 'border-emerald-500/30',
                      icon: '<svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>'
                    }
                  when 'info'
                    {
                      bg: 'bg-blue-500/10',
                      border: 'border-blue-500/20',
                      icon_bg: 'bg-blue-500/20',
                      title_color: 'text-blue-300',
                      action_color: 'text-blue-200',
                      accent_border: 'border-blue-500/30',
                      icon: '<svg class="w-4 h-4 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>'
                    }
                  when 'savings'
                    {
                      bg: 'bg-purple-500/10',
                      border: 'border-purple-500/20',
                      icon_bg: 'bg-purple-500/20',
                      title_color: 'text-purple-300',
                      action_color: 'text-purple-200',
                      accent_border: 'border-purple-500/30',
                      icon: '<svg class="w-4 h-4 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
                    }
                  else
                    {
                      bg: 'bg-gray-500/10',
                      border: 'border-gray-500/20',
                      icon_bg: 'bg-gray-500/20',
                      title_color: 'text-gray-300',
                      action_color: 'text-gray-200',
                      accent_border: 'border-gray-500/30',
                      icon: '<svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
                    }
                  end

    # Agregar badge de prioridad
    priority_badge = case priority
                     when 'high'
                       'bg-red-500/20 text-red-300 border border-red-500/30'
                     when 'medium'
                       'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                     when 'low'
                       'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                     else
                       'bg-gray-500/20 text-gray-300 border border-gray-500/30'
                     end

    base_styles.merge(priority_badge:)
  end
end
