# frozen_string_literal: true

# This module provides utility methods and shared functionality for the application.
module Charteable
  extend ActiveSupport::Concern

  class_methods do
    def flow_dataset
      [{
        label: 'Ingresos',
        data: ReportFilter.new.transaction_type_per_frequency(:income),
        borderColor: '#10b981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true
      }, {
        label: 'Gastos',
        data: ReportFilter.new.transaction_type_per_frequency(:expense),
        borderColor: '#ef4444',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        tension: 0.4,
        fill: true
      }]
    end

    def distribution_dataset
      {
        labels: ReportFilter.new.categories(8).keys,
        datasets: [{
            data: ReportFilter.new.categories(8).values,
            backgroundColor: [
                '#8b5cf6',
                '#06b6d4',
                '#10b981',
                '#f59e0b',
                '#ef4444',
                '#6b7280',
                '#3b82f6',
                '#ec4899',
                '#14b8a6',
                '#f97316'
            ],
            borderWidth: 2,
            borderColor: '#1f2937'
        }]
      }
    end
  end

end
