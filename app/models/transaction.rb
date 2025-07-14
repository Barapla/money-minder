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
    TransactionHistory.create(
      transaction_record: self,
      pre_amount: budget.current_amount,
      post_amount: budget.current_amount - amount
    )
  end

  def update_budget_amount
    budget.update(current_amount: budget.current_amount - amount)
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
end
