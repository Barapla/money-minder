# frozen_string_literal: true

module PayrollServices
  # Genera recordatorios de pago de nómina proyectados basados en EmploymentInformation y PayrollProfile del usuario.
  class ReminderGenerator
    DAYS_PER_PAYMENT = {
      'weekly' => 7,
      'biweekly' => 15,
      'monthly' => 30
    }.freeze

    def initialize(user)
      @user = user
      @employment_info = user.employment_information
      @payroll_profile = user.payroll_profile
    end

    def generate(from_date:, to_date:)
      return [] unless employment_info && payroll_profile

      result = PayrollServices::Calculator.new(payroll_profile).call
      unless result.success?
        Rails.logger.warn("PayrollServices::Calculator falló para usuario #{user.id}: #{result.error}")
        return []
      end

      build_reminders(payment_dates(from_date, to_date), result.data)
    end

    private

    attr_reader :user, :employment_info, :payroll_profile

    def build_reminders(dates, breakdown)
      pay_db = payment_db_value
      period_days = DAYS_PER_PAYMENT.fetch(pay_db, 30)
      net_amount = (BigDecimal(breakdown[:net_salary].to_s) * period_days / 30).round(2)
      dates.map do |d|
        PayrollReminder.new(date: d, net_amount: net_amount, calculation_breakdown: breakdown,
                            payment_frequency: pay_db)
      end
    end

    def payment_dates(from_date, to_date)
      start = employment_info.start_date
      case payment_db_value
      when 'weekly'   then weekly_dates(from_date, to_date)
      when 'biweekly' then biweekly_dates(from_date, to_date)
      when 'monthly'  then monthly_dates(start, from_date, to_date)
      else []
      end
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

    # Quincena fija: días 15 y 30 (o último del mes), ajustados al día hábil anterior; nunca hacia adelante.
    def biweekly_dates(from_date, to_date)
      months_in_range(from_date, to_date)
        .flat_map { |m| quincenal_targets(m) }
        .select { |d| d >= from_date && d <= to_date }
        .sort.uniq
    end

    def months_in_range(from_date, to_date)
      months = []
      current = Date.new(from_date.year, from_date.month, 1)
      while current <= to_date
        months << current
        current >>= 1
      end
      months
    end

    def quincenal_targets(month_start)
      year = month_start.year
      month = month_start.month
      last_day = month_start.end_of_month.day
      [
        adjust_to_business_day(Date.new(year, month, 15)),
        adjust_to_business_day(Date.new(year, month, [30, last_day].min))
      ]
    end

    def adjust_to_business_day(date)
      return date - 1 if date.saturday?
      return date - 2 if date.sunday?

      date
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

    def payment_db_value
      EmploymentInformation.payment_frequencies[employment_info.payment_frequency.to_s].to_s
    end
  end
end
