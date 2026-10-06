# frozen_string_literal: true

# Etiquetas y colores para contadores de días (cortes, vencimientos, nómina),
# compartidos por el dashboard y el detalle de tarjetas de crédito.
module UrgencyHelper
  # Badge compacto: "Hoy" / "Mañana" / "5d"
  def days_label(days)
    return t('dashboard.days.today') if days.to_i <= 0
    return t('dashboard.days.tomorrow') if days.to_i == 1

    t('dashboard.days.short', count: days.to_i)
  end

  # Frase en prosa: "hoy" / "mañana" / "en 5 días"
  def relative_days(days)
    return t('dashboard.days.prose_today') if days.to_i <= 0
    return t('dashboard.days.prose_tomorrow') if days.to_i == 1

    t('dashboard.days.prose_other', count: days.to_i)
  end

  # Rojo a 3 días o menos, ámbar hasta 7, neutro después.
  def urgency_text_class(days)
    return 'text-red-300' if days.to_i <= 3
    return 'text-amber-300' if days.to_i <= 7

    'text-bunker-300'
  end
end
