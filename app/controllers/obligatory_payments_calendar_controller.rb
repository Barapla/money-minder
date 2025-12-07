# frozen_string_literal: true

# ObligatoryPaymentsCalendarController
class ObligatoryPaymentsCalendarController < ApplicationController
  def index
    @date = Date.today
    @obligatory_payments = ObligatoryPayment.includes(:recurrence, :category, :icon, :color)
    @payment_occurrences = generate_payment_occurrences(@date)
  end

  def set_month
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @obligatory_payments = ObligatoryPayment.includes(:recurrence, :category, :icon, :color)
    @payment_occurrences = generate_payment_occurrences(@date)

    render layout: false if turbo_frame_request?
  end

  def day_details
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
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

    render layout: false if turbo_frame_request?
  end

  private

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
