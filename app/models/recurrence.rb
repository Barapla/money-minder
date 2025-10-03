class Recurrence < ApplicationRecord
  # Campos básicos
  # frequency_type: 'daily', 'weekly', 'monthly', 'yearly'
  # frequency_value: cada cuántas unidades (ej: cada 2 semanas = weekly + 2)
  # day_of_week: para frecuencias semanales (0-6, domingo=0)
  # day_of_month: para frecuencias mensuales (1-31)
  # month_of_year: para frecuencias anuales (1-12)

  belongs_to :recurrenceable, polymorphic: true
  belongs_to :recurrenceable_type, class_name: 'Catalog', foreign_key: 'recurrenceable_type_id'
  belongs_to :frequency_type, class_name: 'Catalog', foreign_key: 'frequency_type_id'

  validates :frequency_value, presence: true, numericality: { greater_than: 0 }

  # Validaciones condicionales
  validates :day_of_week, presence: true, if: -> { frequency_type.code == 'weekly' }
  validates :day_of_month, presence: true, if: -> { frequency_type.code == 'monthly' }

  def next_occurrence_from(date = Date.current)
    case frequency_type.code
    when 'monthly'
      calculate_next_monthly_occurrence(date)
    when 'weekly'
      # calculate_next_weekly_occurrence(date)
    # etc...
    end
  end

  private

  def calculate_next_monthly_occurrence(from_date)
    target_day = day_of_month
    next_month = from_date.beginning_of_month + frequency_value.months

    # Manejar casos especiales (días 29-31 en meses cortos)
    if target_day > next_month.end_of_month.day
      next_month.end_of_month
    else
      Date.new(next_month.year, next_month.month, target_day)
    end
  end
end
