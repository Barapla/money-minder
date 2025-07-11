# frozen_string_literal: true

# app/presenters/date_presenter.rb
class DatePresenter < ApplicationPresenter
  FORMATS = {
    default: :default,
    short: :short,
    long: :long
  }.freeze

  def date
    format_date
  end

  def date_in_words_only_month
    I18n.l(@resource.to_date, format: :only_month)
  end

  def date_in_words_short
    format_date(:short)
  end

  def date_in_words_long
    format_date(:long)
  end

  def time
    I18n.l(@resource, format: :time_only)
  end

  def datetime
    combine_datetime
  end

  def datetime_in_words_short
    combine_datetime(:short)
  end

  def datetime_in_words_long
    combine_datetime(:long)
  end

  private

  def format_date(format_key = :default)
    case @resource.to_date
    when Date.today
      'Hoy'
    when Date.yesterday
      'Ayer'
    else
      I18n.l(@resource.to_date, format: FORMATS[format_key])
    end
  end

  def combine_datetime(format_key = :default)
    "#{format_date(format_key)} #{time}"
  end
end
