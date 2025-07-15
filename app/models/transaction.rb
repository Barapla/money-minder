# frozen_string_literal: true

# Transaction model
class Transaction < ApplicationRecord
  belongs_to :budget
  belongs_to :related_budget, class_name: 'Budget', optional: true
  belongs_to :category
  belongs_to :currency
  belongs_to :user
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'
  belongs_to :transaction_type, class_name: 'Catalog', foreign_key: 'transaction_type_id'

  has_one :transaction_history, dependent: :destroy

  after_create :create_transaction_history, :update_budget_amount

  def create_transaction_history
    post_amount = if transaction_type.code == 'expense'
                    budget.current_amount - amount
                  elsif transaction_type.code == 'income'
                    budget.current_amount + amount
                  end

    TransactionHistory.create(
      transaction_record: self,
      pre_amount: budget.current_amount,
      post_amount:
    )
  end

  def update_budget_amount
    budget.update(current_amount: transaction_history.post_amount)
  end

  def preview_amount
    transaction_history&.pre_amount
  end

  def post_amount
    transaction_history&.post_amount
  end

  def used_percentage
    ((amount / transaction_history&.pre_amount.to_f) * 100).round(2)
  end

  def spent_amount_by_category
    budget.transactions
          .joins(:transaction_type)
          .joins(:category)
          .where(category:)
          .where(transaction_type: { code: 'expense' })
          .sum(:amount)
  end

  def spent_amount_the_month_by_category
    budget.transactions
          .joins(:transaction_type)
          .joins(:category)
          .where(category:)
          .where('transaction_date >= ?', transaction_date.beginning_of_month)
          .where('transaction_date <= ?', transaction_date.end_of_month)
          .where(transaction_type: { code: 'expense' })
          .sum(:amount)
  end

  def by_category
    budget.transactions
          .joins(:transaction_type)
          .joins(:category)
          .where(category:)
          .where(transaction_type: { code: 'expense' })
  end
end
