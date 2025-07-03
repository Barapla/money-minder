# frozen_string_literal: true

# app/models/concerns/progress_color_indicator.rb
module ProgressColorIndicator
  extend ActiveSupport::Concern

  # Constantes para los umbrales
  THRESHOLDS = {
    safe: 0.5,      # Hasta 50% - Emerald
    warning: 0.8,   # 50% a 80% - Amber
    danger: 0.95,   # 80% a 95% - Orange
    critical: 1.0   # 95% en adelante - Red
  }.freeze

  # Mapeo de estados a nombres de colores del ColorHelper
  COLORS = {
    safe: 'emerald',
    warning: 'amber',
    danger: 'orange',
    critical: 'red',
    exceeded: 'red'
  }.freeze

  MESSAGES = {
    safe: 'Bajo Control',
    warning: 'Cuidado',
    danger: 'Peligro',
    critical: 'Crítico',
    exceeded: 'Excedido'
  }.freeze

  class_methods do
    # Método principal que retorna el nombre del color
    def progress_color(current, limit)
      return COLORS[:safe] if limit.nil? || limit.zero?

      percentage = current.to_f / limit
      status = determine_progress_status(percentage)

      COLORS[status]
    end

    # Método para obtener el porcentaje
    def progress_percentage(current, limit)
      return 0 if limit.nil? || limit.zero?

      (current.to_f / limit * 100).round(0)
    end

    # Método para obtener el status
    def progress_status(current, limit)
      return :safe if limit.nil? || limit.zero?

      percentage = current.to_f / limit
      status = determine_progress_status(percentage)

      MESSAGES[status]
    end

    private

    def determine_progress_status(percentage)
      case percentage
      when 0..THRESHOLDS[:safe]
        :safe
      when THRESHOLDS[:safe]..THRESHOLDS[:warning]
        :warning
      when THRESHOLDS[:warning]..THRESHOLDS[:danger]
        :danger
      when THRESHOLDS[:danger]..THRESHOLDS[:critical]
        :critical
      else
        :exceeded
      end
    end
  end
end
