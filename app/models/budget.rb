# frozen_string_literal: true

# Budget Model
class Budget < ApplicationRecord
  include Utils::BudgetAttributes
  include ProgressColorIndicator

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :budget_type_id, presence: true
  validates :color_id, presence: true
  validates :icon_id, presence: true

  # Associations
  has_many :transactions, dependent: :destroy
  has_one :credit_card
  has_one :savings_fund

  belongs_to :user
  belongs_to :budget_type, class_name: 'Catalog', foreign_key: 'budget_type_id'
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  # Solo acepta atributos de credit_card si es tipo credit_card
  accepts_nested_attributes_for :credit_card,
                                allow_destroy: true,
                                update_only: true, reject_if: :should_reject_credit_card?
  accepts_nested_attributes_for :savings_fund,
                                allow_destroy: true,
                                update_only: true, reject_if: :should_reject_savings_fund?

  # Construir credit_card automáticamente
  after_initialize :build_budget_type_if_needed

  after_update :update_debt_amount, if: :saved_change_to_current_amount?

  def budget_color
    self.class.progress_color(debt_amount, limit_amount)
  end

  def budget_percentage
    self.class.progress_percentage(debt_amount, limit_amount)
  end

  def budget_status
    self.class.progress_status(debt_amount, limit_amount)
  end

  def transactions_last_days(days = 30)
    transactions
      .where('transaction_date >= ?', days.days.ago)
      .order(transaction_date: :desc)
  end

  def spent_amount_this_month
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', Date.today.at_beginning_of_month)
      .where(transaction_type: { code: 'expense' })
      .sum(:amount)
  end

  def spent_last_days(days = 30)
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', days.days.ago)
      .where(transaction_type: { code: 'expense' })
      .sum(:amount)
  end

  def earnings_last_days(days = 30)
    transactions
      .joins(:transaction_type)
      .where('transaction_date >= ?', days.days.ago)
      .where(transaction_type: { code: 'income' })
      .sum(:amount)
  end

  def difference_last_days(days = 30)
    earnings_last_days(days) - spent_last_days(days)
  end

  def last_change
    date_change = updated_at

    last_transaction = transactions.order(transaction_date: :desc).first
    date_change = last_transaction.transaction_date if last_transaction

    date_change
  end

  private

  def build_budget_type_if_needed
    # Para registros nuevos, siempre construir credit_card
    # Para registros existentes, solo si es credit_card y no existe
    return unless new_record?
    return build_credit_card if credit_card.nil? && budget_type&.code == 'credit_card'

    build_savings_fund if savings_fund.nil? && budget_type&.code == 'savings_fund'
  end

  def should_reject_credit_card?
    # Rechazar los atributos de credit_card si no es tipo credit_card
    budget_type&.code != 'credit_card'
  end

  def should_reject_savings_fund?
    # Rechazar los atributos de savings_fund si no es tipo savings_fund
    budget_type&.code != 'savings_fund'
  end

  def update_debt_amount
    return if credit_card.nil?

    credit_card.update(debt_amount: credit_card.limit_amount - current_amount)
  end
end
