# frozen_string_literal: true

module EmploymentInformationServices
  # Calcula antigüedad laboral y normaliza salarios a todas las periodicidades.
  class Calculator
    DAYS_PER_PERIODICITY = {
      'daily' => 1,
      'weekly' => 7,
      'biweekly' => 15,
      'monthly' => 30,
      'yearly' => 365
    }.freeze

    def self.calculate_seniority(start_date)
      today = Date.current
      years, months = calculate_years_and_months(start_date, today)
      days_in_current_year = calculate_days_in_current_year(start_date, today)
      { years: years, months: months, days_in_current_year: days_in_current_year }
    end

    def self.normalize_salary(amount, periodicity)
      daily_rate = amount / DAYS_PER_PERIODICITY.fetch(periodicity.to_s)
      {
        daily: daily_rate,
        weekly: daily_rate * 7,
        biweekly: daily_rate * 15,
        monthly: daily_rate * 30,
        yearly: daily_rate * 365
      }
    end

    def self.calculate_years_and_months(start_date, today)
      years = today.year - start_date.year
      months = today.month - start_date.month
      day_diff = today.day - start_date.day

      months -= 1 if day_diff.negative?
      if months.negative?
        years -= 1
        months += 12
      end

      [years, months]
    end
    private_class_method :calculate_years_and_months

    def self.calculate_days_in_current_year(start_date, today)
      year_start = Date.new(today.year, 1, 1)
      work_start_in_year = [start_date, year_start].max
      (today - work_start_in_year).to_i + 1
    end
    private_class_method :calculate_days_in_current_year
  end
end
