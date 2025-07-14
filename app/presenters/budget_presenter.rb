# frozen_string_literal: true

# BudgetPresenter is responsible for presenting budget-related data.
class BudgetPresenter < ApplicationPresenter
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper
  def name
    @resource.name
  end

  def budget_type
    @resource.budget_type.value
  end

  def icon
    @resource.icon.value
  end

  def color
    @resource.color.value
  end

  def last_change
    time_ago_in_words(@resource.last_change)
  end

  def debt_amount
    number_to_currency(@resource.debt_amount, unit: '$')
  end

  def current_amount
    number_to_currency(@resource.current_amount, unit: '$')
  end

  def limit_amount
    number_to_currency(@resource.limit_amount, unit: '$')
  end

  def spent_amount_this_month
    number_to_currency(@resource.spent_amount_this_month, unit: '$')
  end

  def spent_last_days
    number_to_currency(@resource.spent_last_days, unit: '$')
  end

  def earnings_last_days
    number_to_currency(@resource.earnings_last_days, unit: '$')
  end

  def difference_last_days
    number_to_currency(@resource.difference_last_days, unit: '$')
  end

  def status
    @resource.budget_status
  end

  def budget_percentage
    "#{@resource.budget_percentage}%"
  end

  def cutting_day
    @resource.cutting_day.strftime('%d %b')
  end

  def payday
    @resource.payday.strftime('%d %b')
  end

  def created_at
    @resource.created_at.strftime('%d %b %Y')
  end
end
