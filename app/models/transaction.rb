# frozen_string_literal: true

# Transaction model
class Transaction < ApplicationRecord
  include Utils::Transaction::TransactionHistory
  include Utils::Transaction::RelatedTransaction
  include Utils::Transaction::AmountUsage
  include Utils::Transaction::TransactionType
  belongs_to :budget
  belongs_to :related_budget, class_name: 'Budget', optional: true
  belongs_to :category
  belongs_to :currency
  belongs_to :user
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'
  belongs_to :transaction_type, class_name: 'Catalog', foreign_key: 'transaction_type_id'

  has_one :transaction_history, dependent: :destroy

  before_validation :set_default_values

  def set_default_values
    self.currency ||= Currency.default
  end

  def transactions_by_category
    budget.transactions
          .joins(:category)
          .where(category:)
  end
end
