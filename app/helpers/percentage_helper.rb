# frozen_string_literal: true

# app/helpers/percentage_helper.rb
module PercentageHelper
  def calculate_percentage(part, total)
    return 0 if total.zero?

    ((part.to_f / total) * 100).round(2)
  end

  def format_percentage(value)
    "#{value}%"
  end

  def progress_color(debt_amount, limit_amount)
    if debt_amount < limit_amount * 0.5
      'green'
    elsif debt_amount < limit_amount
      'yellow'
    else
      'red'
    end
  end

  def average(values)
    return 0 if values.empty?

    (values.sum / values.size).round(2)
  end
end
