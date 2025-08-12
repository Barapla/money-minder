# frozen_string_literal: true

# This module provides utility methods and shared functionality for the application.
module Charteable
  extend ActiveSupport::Concern

  def flow_dataset
    {
      labels: labels_for_period,
      datasets: [{
        label: 'Ingresos',
        data: transaction_type_per_frequency(:income),
        borderColor: '#10b981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        tension: 0.4,
        fill: true
      }, {
        label: 'Gastos',
        data: transaction_type_per_frequency(:expense),
        borderColor: '#ef4444',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        tension: 0.4,
        fill: true
      }]
    }
  end

  def distribution_dataset(transaction_type)
    {
      labels: categories(transaction_type, 8).keys,
      datasets: [{
          data: categories(transaction_type, 8).values,
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

  def report_dataset
    income_data = transaction_type_per_frequency(:income)
    expense_data = transaction_type_per_frequency(:expense)
    balance_data = income_data.sum - expense_data.sum
    no_transactions =  transaction_count

    {
      incomeData: income_data.sum,
      expenseData: expense_data.sum,
      balanceData: balance_data,
      noTransactions: no_transactions
    }
  end

  def comparison_dataset
    {
      labels: budgets_names,
      datasets: [{
          label: 'Ingresos',
          data: budgets_pluck_transaction_type("income"),
          backgroundColor: 'rgba(139, 92, 246, 0.3)',
          borderColor: '#8b5cf6',
          borderWidth: 2
      }, {
          label: 'Gastos',
          data: budgets_pluck_transaction_type("expense"),
          backgroundColor: 'rgba(239, 68, 68, 0.8)',
          borderColor: '#ef4444',
          borderWidth: 2
      }]
    }
  end

end
