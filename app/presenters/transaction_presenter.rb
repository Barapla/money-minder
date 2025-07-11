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
end
