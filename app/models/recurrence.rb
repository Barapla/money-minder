# frozen_string_literal: true

# Modelo de recurrencia para pagos y transacciones periódicas.
# Soporta frecuencias: daily, weekly, biweekly, monthly, yearly.
# frequency_value indica cada cuántas unidades (ej: 2 para "cada 2 meses").
# rubocop:disable Metrics/ClassLength -- clase cohesiva: todos los métodos calculan ocurrencias de una recurrencia
class Recurrence < ApplicationRecord
  belongs_to :recurrenceable, polymorphic: true, optional: true
  belongs_to :recurrenceable_type_catalog, class_name: 'Catalog', foreign_key: 'recurrenceable_type_id'
  belongs_to :frequency_type, class_name: 'Catalog', foreign_key: 'frequency_type_id'

  validates :frequency_value, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true

  def next_occurrence_from(date = Date.current)
    case frequency_type.code
    when 'monthly' then calculate_next_monthly_occurrence(date)
    when 'daily' then calculate_next_interval_occurrence(date, frequency_value)
    when 'weekly' then calculate_next_interval_occurrence(date, frequency_value * 7)
    when 'biweekly' then calculate_next_interval_occurrence(date, 14)
    when 'yearly' then calculate_next_yearly_occurrence(date)
    end
  end

  def next_n_occurrences(count, from_date = Date.current)
    occurrences = []
    current_date = from_date

    count.times do
      next_date = next_occurrence_from(current_date)
      break if next_date.nil?

      occurrences << next_date
      current_date = next_date + 1.day
    end

    occurrences
  end

  def occurrences_in_range(range_start, range_end)
    occurrences = []
    current_date = range_start

    while current_date <= range_end
      next_date = next_occurrence_from(current_date)
      break if next_date.nil? || next_date > range_end

      occurrences << next_date if next_date >= range_start && !occurrences.include?(next_date)
      current_date = advance_past(next_date, current_date)
    end

    occurrences
  end

  private

  def advance_past(next_date, current_date)
    current_date = next_date if next_date == current_date
    current_date + 1.day
  end

  def occurrence_day_in_month(year, month)
    target_day = start_date.day
    capped_day = [target_day, Date.new(year, month, -1).day].min
    Date.new(year, month, capped_day)
  end

  def months_offset(from_date)
    (from_date.year * 12 + from_date.month) - (start_date.year * 12 + start_date.month)
  end

  def current_month_valid_occurrence(from_date)
    candidate = occurrence_day_in_month(from_date.year, from_date.month)
    return nil if candidate < from_date
    return nil if end_date.present? && candidate > end_date

    candidate
  end

  def next_valid_monthly_occurrence(from_date, remainder)
    months_to_advance = remainder.zero? ? frequency_value : (frequency_value - remainder)
    next_month = from_date.beginning_of_month + months_to_advance.months
    candidate = occurrence_day_in_month(next_month.year, next_month.month)
    return nil if end_date.present? && candidate > end_date

    candidate
  end

  def calculate_next_monthly_occurrence(from_date)
    effective_from = valid_from_date(from_date)
    remainder = months_offset(effective_from) % frequency_value

    if remainder.zero?
      hit = current_month_valid_occurrence(effective_from)
      return hit if hit
    end

    next_valid_monthly_occurrence(effective_from, remainder)
  end

  def calculate_next_interval_occurrence(from_date, days)
    effective_from = valid_from_date(from_date)
    periods = ((effective_from - start_date).to_i / days.to_f).ceil
    next_occurrence = start_date + (periods * days).days
    next_occurrence += days.days unless next_occurrence >= effective_from
    return nil if end_date.present? && next_occurrence > end_date

    next_occurrence
  end

  def calculate_next_yearly_occurrence(from_date)
    effective_from = valid_from_date(from_date)
    candidate = candidate_yearly_occurrence(effective_from)
    return nil if end_date.present? && candidate > end_date

    candidate
  end

  def candidate_yearly_occurrence(from_date)
    years_offset = from_date.year - start_date.year
    remainder = years_offset % frequency_value

    if remainder.zero?
      current = yearly_occurrence_date(from_date.year)
      return current if current >= from_date
    end

    years_ahead = remainder.zero? ? frequency_value : (frequency_value - remainder)
    yearly_occurrence_date(from_date.year + years_ahead)
  end

  def yearly_occurrence_date(year)
    day = start_date.day
    month = start_date.month
    day = 28 if month == 2 && day == 29 && !Date.leap?(year)
    Date.new(year, month, day)
  end

  def valid_from_date(from_date)
    [from_date, start_date].max
  end
end
# rubocop:enable Metrics/ClassLength
