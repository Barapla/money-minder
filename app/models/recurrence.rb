class Recurrence < ApplicationRecord
  # Campos básicos
  # frequency_type: 'daily', 'weekly', 'monthly', 'yearly'
  # frequency_value: cada cuántas unidades (ej: cada 2 semanas = weekly + 2)
  # day_of_week: para frecuencias semanales (0-6, domingo=0)
  # day_of_month: para frecuencias mensuales (1-31)
  # month_of_year: para frecuencias anuales (1-12)

  belongs_to :recurrenceable, polymorphic: true, optional: true
  belongs_to :recurrenceable_type_catalog, class_name: 'Catalog', foreign_key: 'recurrenceable_type_id'
  belongs_to :frequency_type, class_name: 'Catalog', foreign_key: 'frequency_type_id'

  validates :frequency_value, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true

  # Validaciones condicionales
  validates :day_of_week, presence: true, if: -> { frequency_type&.code == 'weekly' }
  validates :day_of_month, presence: true, if: -> { frequency_type&.code == 'monthly' || frequency_type&.code == 'yearly' }

  def next_occurrence_from(date = Date.current)
    case frequency_type.code
    when 'monthly'
      calculate_next_monthly_occurrence(date)
    when 'weekly'
      # calculate_next_weekly_occurrence(date)
    # etc...
    when 'daily'
      calculate_next_daily_occurrence(date)
    end
  end

  # Genera múltiples ocurrencias futuras
  def next_n_occurrences(n, from_date = Date.current)
    occurrences = []
    current_date = from_date

    n.times do
      next_date = next_occurrence_from(current_date)
      break if next_date.nil?

      occurrences << next_date
      current_date = next_date
    end

    occurrences
  end

  # Genera todas las ocurrencias dentro de un rango de fechas
  def occurrences_in_range(start_date, end_date)
    occurrences = []
    current_date = start_date

    while current_date <= end_date
      next_date = next_occurrence_from(current_date)
      break if next_date.nil? || next_date > end_date

      occurrences << next_date if next_date >= start_date && !occurrences.include?(next_date)

      # Ensure we advance to avoid infinite loops
      if next_date == current_date
        current_date = current_date + 1.day
      else
        current_date = next_date + 1.day
      end
    end

    occurrences
  end

  private

  def calculate_next_monthly_occurrence(from_date)
    target_day = day_of_month

    # First try current month
    current_month_occurrence = begin
      Date.new(from_date.year, from_date.month, [target_day, from_date.end_of_month.day].min)
    rescue ArgumentError
      from_date.end_of_month
    end

    # If the target day in current month is today or in the future, use it
    if current_month_occurrence >= from_date
      return current_month_occurrence
    end

    # Otherwise, calculate for next occurrence based on frequency
    next_month = from_date.beginning_of_month + frequency_value.months

    # Manejar casos especiales (días 29-31 en meses cortos)
    if target_day > next_month.end_of_month.day
      next_month.end_of_month
    else
      Date.new(next_month.year, next_month.month, target_day)
    end
  end

  def calculate_next_daily_occurrence(from_date)
    days_difference = (from_date - start_date).to_i
    intervals_passed = (days_difference / frequency_value.to_f).ceil
    next_occurrence = start_date + (intervals_passed * frequency_value).days

    next_occurrence >= from_date ? next_occurrence : next_occurrence + frequency_value.days
  end
end
