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

  def current_amount
    number_to_currency(@resource.current_amount, unit: '$')
  end

  def limit_amount
    number_to_currency(@resource.limit_amount, unit: '$')
  end

  def available_amount
    available_amount = @resource.personal? ? @resource.current_amount : @resource.limit_amount - @resource.current_amount
    number_to_currency(available_amount, unit: '$')
  end

  def budget_percentage
    "#{@resource.budget_percentage}%"
  end
end
