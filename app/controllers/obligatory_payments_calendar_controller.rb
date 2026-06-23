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
    @day_payments = payments_for_date(@date, @obligatory_payments)
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

  def payments_for_date(date, payments)
    payment_ids = payments.pluck(:id)
    recurrence_map = build_recurrence_map(payment_ids)

    payments.select do |payment|
      recurrence_map[payment.id]&.occurrences_in_range(date, date)&.any?
    end
  end

  def build_recurrence_map(payment_ids)
    return {} if payment_ids.empty?

    Recurrence
      .where('recurrences.recurrenceable_type::text = ?', 'ObligatoryPayment')
      .where(recurrenceable_id: payment_ids)
      .includes(:frequency_type)
      .each_with_object({}) { |rec, map| map[rec.recurrenceable_id] = rec }
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
  rescue StandardError => e
    Rails.logger.error("PayrollReminder error for date #{date}: #{e.message}")
    []
  end

  def reminder_generator
    @reminder_generator ||= PayrollServices::ReminderGenerator.new(current_user)
  end

  def generate_payment_occurrences(date)
    payment_ids = @obligatory_payments.pluck(:id)
    return {} if payment_ids.empty?

    recurrence_map = build_recurrence_map(payment_ids)
    accumulate_occurrences(@obligatory_payments, recurrence_map, date)
  end

  def accumulate_occurrences(payments, recurrence_map, date)
    payments.each_with_object({}) do |payment, occurrences|
      recurrence = recurrence_map[payment.id]
      next unless recurrence

      add_occurrences(occurrences, recurrence, payment, date)
    end
  end

  def add_occurrences(occurrences, recurrence, payment, date)
    recurrence.occurrences_in_range(date.beginning_of_month, date.end_of_month).each do |occurrence_date|
      occurrences[occurrence_date] ||= []
      occurrences[occurrence_date] << payment
    end
  end
end
