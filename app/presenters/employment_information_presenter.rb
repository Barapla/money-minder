# frozen_string_literal: true

# Presentation layer for EmploymentInformation: formatea antigüedad y salarios normalizados.
class EmploymentInformationPresenter < ApplicationPresenter
  include ActionView::Helpers::NumberHelper

  PERIODICITY_LABELS = {
    'daily' => 'Diario',
    'weekly' => 'Semanal',
    'biweekly' => 'Quincenal',
    'monthly' => 'Mensual',
    'yearly' => 'Anual'
  }.freeze

  def initialize(employment_information)
    super(employment_information)
    @seniority = EmploymentInformationServices::Calculator.calculate_seniority(@resource.start_date)
    @normalized = EmploymentInformationServices::Calculator.normalize_salary(
      @resource.gross_salary_amount,
      @resource.salary_periodicity
    )
  end

  def seniority_text
    parts = []
    parts << "#{@seniority[:years]} #{@seniority[:years] == 1 ? 'año' : 'años'}" if @seniority[:years].positive?
    parts << "#{@seniority[:months]} #{@seniority[:months] == 1 ? 'mes' : 'meses'}" if @seniority[:months].positive?
    parts << "#{@seniority[:days_in_current_year]} días en el año actual"
    parts.join(', ')
  end

  def seniority_years
    @seniority[:years]
  end

  def seniority_months
    @seniority[:months]
  end

  def days_in_current_year
    @seniority[:days_in_current_year]
  end

  def periodicity_label
    PERIODICITY_LABELS.fetch(@resource.salary_periodicity, @resource.salary_periodicity)
  end

  def formatted_salary(periodicity)
    amount = @normalized.fetch(periodicity.to_sym, 0)
    number_to_currency(amount, unit: '$', separator: '.', delimiter: ',')
  end

  def normalized_salaries
    @normalized.transform_values { |v| number_to_currency(v, unit: '$', separator: '.', delimiter: ',') }
  end

  def formatted_start_date
    @resource.start_date.strftime('%d/%m/%Y')
  end

  def job_title
    @resource.job_title
  end

  def original_salary_formatted
    number_to_currency(@resource.gross_salary_amount, unit: '$', separator: '.', delimiter: ',')
  end

  private

  attr_reader :resource
end
