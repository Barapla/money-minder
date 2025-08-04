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
  belongs_to :recurring_transaction, optional: true

  has_one :transaction_history, dependent: :destroy

  before_validation :set_default_values

  scope :by_category, lambda { |category|
    joins(:category).where(categories: { name: category })
  }
  scope :expense, -> { joins(:transaction_type).where(transaction_type: { code: 'expense' }) }
  scope :income, -> { joins(:transaction_type).where(transaction_type: { code: 'income' }, related_transaction_id: nil ) }
  scope :transfer, -> { joins(:transaction_type).where(transaction_type: { code: 'transfer' }) }


  def set_default_values
    self.currency ||= Currency.default
  end

  def transactions_by_category
    budget.transactions
          .joins(:category)
          .where(category:)
  end
end
