# frozen_string_literal: true

# Presentation layer for EmploymentInformation: formatea antigüedad y salarios normalizados.
class EmploymentInformationPresenter < ApplicationPresenter # rubocop:disable Metrics/ClassLength
  include ActionView::Helpers::NumberHelper

  CALCULATION_PERIODICITY_LABELS = {
    'weekly' => 'Semanal',
    'biweekly' => 'Quincenal',
    'monthly' => 'Mensual',
    'annual' => 'Anual'
  }.freeze

  PAYMENT_FREQUENCY_LABELS = {
    'weekly' => 'Semanal',
    'biweekly' => 'Quincenal',
    'monthly' => 'Mensual'
  }.freeze

  DAY_NAMES_ES = %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado].freeze

  def initialize(employment_information)
    super(employment_information)
    @seniority = EmploymentInformationServices::Calculator.calculate_seniority(@resource.start_date)
    calc_db_value = EmploymentInformation.calculation_periodicities[@resource.calculation_periodicity.to_s].to_s
    @normalized = EmploymentInformationServices::Calculator.normalize_salary(
      @resource.gross_salary_amount,
      calc_db_value
    )
  end

  def seniority_text
    parts = []
    parts << "#{@seniority[:years]} #{@seniority[:years] == 1 ? 'año' : 'años'}" if @seniority[:years].positive?
    parts << "#{@seniority[:months]} #{@seniority[:months] == 1 ? 'mes' : 'meses'}" if @seniority[:months].positive?
    parts << "#{@seniority[:days_in_current_year]} días en el año actual"
    parts.join(', ')
  end

  def seniority_years        = @seniority[:years]
  def seniority_months       = @seniority[:months]
  def days_in_current_year   = @seniority[:days_in_current_year]

  def calculation_periodicity_label
    db_val = EmploymentInformation.calculation_periodicities[@resource.calculation_periodicity.to_s].to_s
    CALCULATION_PERIODICITY_LABELS.fetch(db_val, @resource.calculation_periodicity.to_s)
  end

  def payment_frequency_label
    db_val = EmploymentInformation.payment_frequencies[@resource.payment_frequency.to_s].to_s
    PAYMENT_FREQUENCY_LABELS.fetch(db_val, @resource.payment_frequency.to_s)
  end

  def periodicity_label
    calculation_periodicity_label
  end

  def formatted_salary(periodicity)
    amount = @normalized.fetch(periodicity.to_sym, 0)
    number_to_currency(amount, unit: '$', separator: '.', delimiter: ',')
  end

  def normalized_salaries
    @normalized.transform_values { |v| number_to_currency(v, unit: '$', separator: '.', delimiter: ',') }
  end

  def formatted_start_date    = @resource.start_date.strftime('%d/%m/%Y')
  def job_title               = @resource.job_title

  def weekly_payment_day_name
    return nil unless @resource.start_date

    DAY_NAMES_ES[@resource.start_date.wday]
  end

  def original_salary_formatted
    number_to_currency(@resource.gross_salary_amount, unit: '$', separator: '.', delimiter: ',')
  end

  def next_payment_date
    pay_db_val = EmploymentInformation.payment_frequencies[@resource.payment_frequency.to_s].to_s
    case pay_db_val
    when 'weekly'   then next_weekly_payment
    when 'biweekly' then next_biweekly_payment
    when 'monthly'  then next_monthly_payment
    end
  end

  def next_payment_date_formatted
    date = next_payment_date
    return nil unless date

    date.strftime('%d/%m/%Y')
  end

  def show_payment_reminder?
    @resource.payment_frequency.present?
  end

  private

  attr_reader :resource

  def next_weekly_payment
    return nil unless @resource.start_date

    today = Date.current
    days_ahead = (@resource.start_date.wday - today.wday) % 7
    days_ahead = 7 if days_ahead.zero?
    today + days_ahead
  end

  def next_biweekly_payment
    today = Date.current
    candidates = biweekly_payment_dates(today).compact.select { |d| d >= today }
    return candidates.min unless candidates.empty?

    nxt = today >> 1
    last_working_day_on_or_before(Date.new(nxt.year, nxt.month, 15))
  end

  def biweekly_payment_dates(date)
    [
      last_working_day_on_or_before(Date.new(date.year, date.month, 15)),
      last_working_day_on_or_before(Date.new(date.year, date.month, -1))
    ]
  end

  def next_monthly_payment
    today = Date.current
    candidate = last_working_day_on_or_before(Date.new(today.year, today.month, -1))
    return candidate if candidate >= today

    nxt = today >> 1
    last_working_day_on_or_before(Date.new(nxt.year, nxt.month, -1))
  end

  # Solo omite sábados y domingos; los días festivos mexicanos no se consideran.
  def last_working_day_on_or_before(date)
    date -= 1 while date.saturday? || date.sunday?
    date
  end
end
