# frozen_string_literal: true

# Calcula la distribucion de gastos por categoria dentro de un rango de fechas (FEAT-037).
class CategoryBreakdownCalculator
  def initialize(user, date_range)
    @user = user
    @date_range = date_range
  end

  def call
    sums = expenses.group(:category_id).sum(:amount)
    total = sums.values.sum
    names = category_names_for(sums.keys)

    sums.map { |category_id, amount| breakdown_entry(names[category_id], amount, total) }
        .sort_by { |item| -item[:amount] }
  end

  private

  attr_reader :user, :date_range

  def expenses
    user.transactions.expense.where(transaction_date: date_range)
  end

  def category_names_for(category_ids)
    Category.where(id: category_ids.compact).pluck(:id, :name).to_h
  end

  def breakdown_entry(category_name, amount, total)
    {
      category_name: category_name || 'Sin categoría',
      amount: amount.to_f,
      percentage: total.positive? ? (amount / total * 100).round(2).to_f : 0.0
    }
  end
end
