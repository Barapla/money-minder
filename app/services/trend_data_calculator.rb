# frozen_string_literal: true

# Calcula ingresos, gastos y balance de los ultimos 6 meses para graficas de tendencia (FEAT-038).
class TrendDataCalculator
  MONTHS = 6

  def initialize(user)
    @user = user
  end

  def call
    income_sums = grouped_sums(user.transactions.income)
    expense_sums = grouped_sums(user.transactions.expense)

    months.map { |month| entry_for(month, income_sums, expense_sums) }
  end

  private

  attr_reader :user

  def months
    (0...MONTHS).map { |i| range_start.months_since(i) }
  end

  def range_start
    @range_start ||= (MONTHS - 1).months.ago(Date.current).beginning_of_month
  end

  def grouped_sums(scope)
    scope.where(transaction_date: range_start..Date.current.end_of_month)
         .group("TO_CHAR(transaction_date, 'YYYY-MM')")
         .sum(:amount)
  end

  def entry_for(month, income_sums, expense_sums)
    key = month.strftime('%Y-%m')
    income = income_sums[key].to_f
    expenses = expense_sums[key].to_f

    { month: key, income: income, expenses: expenses, balance: (income - expenses).round(2) }
  end
end
