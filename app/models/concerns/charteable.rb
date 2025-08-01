# frozen_string_literal: true

# This module provides utility methods and shared functionality for the application.
module Charteable
  extend ActiveSupport::Concern

  class_methods do
    def flow_dataset
      [{
        label: 'Ingresos',
        data: self.first.earned_per_frequency,
        borderColor: '#10b981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true
      }, {
        label: 'Gastos',
        data: self.first.expensed_per_frequency,
        borderColor: '#ef4444',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        tension: 0.4,
        fill: true
      }]
    end
  end

end
