# frozen_string_literal: true

# ObligatoryPaymentsCalendarController
class ObligatoryPaymentsCalendarController < ApplicationController
  before_action :set_payroll_reminders_for_month, only: %i[index set_month]

  def index
    @date = Date.today
    @obligatory_payments = ObligatoryPayment.includes(:recurrence, :category, :icon, :color)
    @payment_occurrences = generate_payment_occurrences(@date)
  end

  def set_month
    @date = safe_parse_date(params[:date])
    @obligatory_payments = ObligatoryPayment.includes(:recurrence, :category, :icon, :color)
    @payment_occurrences = generate_payment_occurrences(@date)

    render layout: false if turbo_frame_request?
  end

  def day_details
    @date = safe_parse_date(params[:date])
    @obligatory_payments = ObligatoryPayment.includes(:category, :icon, :color)

    # Get recurrences for all payments using raw SQL
    payment_ids = @obligatory_payments.pluck(:id)
    recurrences = payment_ids.any? ? Recurrence
      .where("recurrences.recurrenceable_type::text = ?", 'ObligatoryPayment')
      .where(recurrenceable_id: payment_ids)
      .includes(:frequency_type) : []

    # Build recurrence map
    recurrence_map = {}
    recurrences.each { |rec| recurrence_map[rec.recurrenceable_id] = rec }

    # Filtrar solo los pagos que vencen en esta fecha específica
    @day_payments = @obligatory_payments.select do |payment|
      recurrence = recurrence_map[payment.id]
      recurrence&.occurrences_in_range(@date, @date)&.any?
    end

    @total_amount = @day_payments.sum(&:amount)
    @payroll_reminders = payroll_reminders_for_date(@date)

    render layout: false if turbo_frame_request?
  end

  private

  def safe_parse_date(date_param)
    return Date.today unless date_param

    Date.parse(date_param)
  rescue ArgumentError
    Date.today
  end

  def set_payroll_reminders_for_month
    return unless current_user

    date = safe_parse_date(params[:date]) || Date.today
    reminders = reminder_generator.generate(from_date: date.beginning_of_month, to_date: date.end_of_month)
    @payroll_reminders_by_date = reminders.group_by(&:date)
  end

  def payroll_reminders_for_date(date)
    return [] unless current_user

    reminder_generator.generate(from_date: date, to_date: date)
  end

  def reminder_generator
    @reminder_generator ||= PayrollServices::ReminderGenerator.new(current_user)
  end

  def generate_payment_occurrences(date)
    start_date = date.beginning_of_month
    end_date = date.end_of_month

    payment_occurrences = {}

    # Get all recurrences for obligatory payments using raw SQL to avoid ActiveRecord confusion
    payment_ids = @obligatory_payments.pluck(:id)
    return payment_occurrences if payment_ids.empty?

    recurrences = Recurrence
      .where("recurrences.recurrenceable_type::text = ?", 'ObligatoryPayment')
      .where(recurrenceable_id: payment_ids)
      .includes(:frequency_type)

    # Build a hash of payment_id => recurrence
    recurrence_map = {}
    recurrences.each do |rec|
      recurrence_map[rec.recurrenceable_id] = rec
    end

    # Generate occurrences for each payment
    @obligatory_payments.each do |payment|
      recurrence = recurrence_map[payment.id]
      next unless recurrence

      occurrences = recurrence.occurrences_in_range(start_date, end_date)

      occurrences.each do |occurrence_date|
        payment_occurrences[occurrence_date] ||= []
        payment_occurrences[occurrence_date] << payment
      end
    end

    payment_occurrences
  end
end
