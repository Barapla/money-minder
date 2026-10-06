# frozen_string_literal: true

# Gráfica de reparto de gasto del dashboard. Las etiquetas de días viven en UrgencyHelper.
module DashboardHelper
  # Paleta fija del donut de reparto de gasto (top 8 categorías).
  DONUT_COLORS = %w[#a855f7 #3b82f6 #fb923c #ec4899 #10b981 #06b6d4 #f59e0b #677a90].freeze

  # Construye el conic-gradient acumulando los porcentajes de cada categoría.
  def expense_donut_gradient(items)
    cursor = 0.0
    stops = items.each_with_index.map do |item, index|
      from = cursor
      cursor += item[:share_percent].to_f
      "#{DONUT_COLORS[index % DONUT_COLORS.size]} #{from.round(2)}% #{cursor.round(2)}%"
    end
    "conic-gradient(#{stops.join(', ')})"
  end

  def donut_color(index)
    DONUT_COLORS[index % DONUT_COLORS.size]
  end
end
