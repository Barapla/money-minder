# frozen_string_literal: true

# CurrencyPresenter is responsible for presenting budget-related data.
class CurrencyPresenter < ApplicationPresenter
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper

  def name
    @resource.name
  end

  def symbol
    @resource.symbol
  end

  def code
    @resource.code
  end
end
