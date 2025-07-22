# frozen_string_literal: true

# BudgetPresenter is responsible for presenting budget-related data.
class RecurringTransactionPresenter < ApplicationPresenter
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper

  FREQUENCY_OPTIONS = {
    'daily' => 'Diario',
    'weekly' => 'Semanal',
    'bi_weekly' => 'Quincenal',
    'monthly' => 'Mensual',
    'bi_monthly' => 'Bimestral',
    'quarterly' => 'Trimestral',
    'semi_annually' => 'Semestral',
    'annually' => 'Anual'
  }.freeze

  def frequency
    FREQUENCY_OPTIONS[@resource.frequency] || 'Desconocida'
  end

  def category
    Category.find(@resource.transaction_options['category_id']).name
  end

  def budget
    @resource.budget ? @resource.budget.name : 'Sin presupuesto'
  end

  def icon
    Catalog.find(@resource.transaction_options['icon_id']).value
  end

  def created_at
    @resource.created_at.strftime('%d %b %Y')
  end

  def updated_at
    @resource.updated_at.strftime('%d %b %Y')
  end
end
