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
  has_one :credit_card_cycle_transaction, dependent: :destroy

  before_validation :set_default_values

  validate :budget_belongs_to_user, if: :budget_id?
  validate :transfer_origin_must_hold_own_money, if: :transfer?

  scope :by_category, lambda { |category|
    joins(:category).where(categories: { name: category })
  }
  scope :by_transaction_type, lambda { |type_code|
    joins(:transaction_type).where(transaction_type: { code: type_code })
  }
  scope :expense, -> { by_transaction_type('expense') }
  scope :income, -> { by_transaction_type('income').where(related_transaction_id: nil) }
  scope :transfer, -> { by_transaction_type('transfer') }
  scope :transfers_and_income, -> { transfer.or(where.not(related_transaction_id: nil)) }
  scope :report, -> { by_transaction_type(%w[expense income]).where(related_transaction_id: nil) }

  def set_default_values
    self.currency ||= Currency.default
  end

  def transactions_by_category
    budget.transactions
          .joins(:category)
          .where(category:)
  end

  private

  def budget_belongs_to_user
    return if budget&.user_id == user_id

    errors.add(:budget_id, 'debe pertenecer al mismo usuario')
  end

  # Un traspaso mueve dinero que ya es tuyo. Desde una tarjeta de credito seria una
  # disposicion de efectivo: cobra intereses desde el dia uno, tiene su propio limite
  # y no entra al ciclo como compra ni como pago. Se bloquea en vez de reventar en
  # determine_cycle_cutting_date_for_transaction con "Unsupported transaction type".
  def transfer_origin_must_hold_own_money
    return unless budget&.budget_type&.code == 'credit_card'

    errors.add(:budget_id,
               'no puede ser una tarjeta de crédito: un traspaso sale de efectivo, débito o un fondo de ahorro')
  end
end
