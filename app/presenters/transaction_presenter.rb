# frozen_string_literal: true

# BudgetPresenter is responsible for presenting budget-related data.
class TransactionPresenter < ApplicationPresenter
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper
  def transaction_type
    @resource.transaction_type.value
  end

  def category
    @resource.category.name
  end

  def icon
    @resource.icon.value
  end

  def color
    @resource.color.value
  end

  def amount
    number_to_currency(@resource.amount, unit: '$')
  end

  def preview_amount
    number_to_currency(@resource.preview_amount, unit: '$')
  end

  def post_amount
    number_to_currency(@resource.post_amount, unit: '$')
  end

  def used_percentage
    "#{@resource.used_percentage}%"
  end

  def description
    @resource.description
  end

  def transaction_date
    DatePresenter.new(@resource.transaction_date).date_in_words_long
  end

  def budget
    @resource.budget.name
  end

  def created_at
    @resource.created_at.strftime('%d %b %Y')
  end

  def updated_at
    @resource.updated_at.strftime('%d %b %Y')
  end

  def spent_amount_the_month_by_category
    number_to_currency(@resource.spent_amount_the_month_by_category, unit: '$')
  end
end
