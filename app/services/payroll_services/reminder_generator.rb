# frozen_string_literal: true

module PayrollServices
  # Genera recordatorios de pago de nómina proyectados basados en EmploymentInformation y PayrollProfile del usuario.
  class ReminderGenerator
    def initialize(user)
      @user = user
      @employment_info = user.employment_information
      @payroll_profile = user.payroll_profile
    end

    def generate(from_date:, to_date:)
      return [] unless employment_info && payroll_profile

      result = PayrollServices::Calculator.new(payroll_profile).call
      return [] unless result.success?

      build_reminders(payment_dates(from_date, to_date), result.data)
    end

    private

    attr_reader :user, :employment_info, :payroll_profile

    def build_reminders(dates, breakdown)
      net_amount = breakdown[:net_salary]
      periodicity = employment_info.salary_periodicity
      dates.map do |date|
        PayrollReminder.new(
          date: date, net_amount: net_amount, calculation_breakdown: breakdown, periodicity: periodicity
        )
      end
    end

    def payment_dates(from_date, to_date)
      start = employment_info.start_date

      case employment_info.salary_periodicity
      when 'daily' then daily_dates(start, from_date, to_date)
      when 'weekly' then weekly_dates(from_date, to_date)
      when 'biweekly' then biweekly_dates(start, from_date, to_date)
      when 'monthly' then monthly_dates(start, from_date, to_date)
      when 'yearly' then yearly_dates(start, from_date, to_date)
      else []
      end
    end

    def daily_dates(start, from_date, to_date)
      first = [start, from_date].max
      (first..to_date).to_a
    end

    # Los pagos semanales son siempre los jueves (día hábil fijo por convención de nómina).
    def weekly_dates(from_date, to_date)
      dates = []
      days_until_thursday = (4 - from_date.wday) % 7
      current = from_date + days_until_thursday
      while current <= to_date
        dates << current
        current += 7
      end
      dates
    end

    # La quincena se ajusta al día hábil anterior si cae en fin de semana (nunca se pasa de la fecha calculada).
    def biweekly_dates(start, from_date, to_date)
      fixed_interval_dates(start, from_date, to_date, 15).map { |d| adjust_to_business_day(d) }
    end

    def fixed_interval_dates(start, from_date, to_date, interval)
      dates = []
      current = first_occurrence_on_or_after(start, from_date, interval)
      while current <= to_date
        dates << current
        current += interval
      end
      dates
    end

    # Calcula la primera fecha de pago en o después de from_date, manteniendo el ciclo desde start.
    def first_occurrence_on_or_after(start, from_date, interval)
      return start if start >= from_date

      elapsed_days = (from_date - start).to_i
      cycles = (elapsed_days.to_f / interval).ceil
      start + (cycles * interval)
    end

    # Ajusta al día hábil anterior si cae en sábado o domingo.
    def adjust_to_business_day(date)
      case date.wday
      when 6 then date - 1  # sábado -> viernes
      when 0 then date - 2  # domingo -> viernes
      else date
      end
    end

    def monthly_dates(start, from_date, to_date)
      dates = []
      current = start
      current >>= 1 while current < from_date
      while current <= to_date
        dates << current
        current >>= 1
      end
      dates
    end

    def yearly_dates(start, from_date, to_date)
      dates = []
      current = start
      current >>= 12 while current < from_date
      while current <= to_date
        dates << current
        current >>= 12
      end
      dates
    end
  end
end
