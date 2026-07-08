# frozen_string_literal: true

# Requisito que el usuario debe cumplir para mantener un beneficio en su valor base.
class FinancialProductBenefitRequirement < ApplicationRecord
  belongs_to :benefit, class_name: 'FinancialProductBenefit',
                       foreign_key: 'financial_product_benefit_id',
                       inverse_of: :requirements

  enum :requirement_type, {
    min_transactions: 0,
    min_transactions_with_amount: 1,
    accumulated_amount: 2,
    monthly_fee: 3
  }

  validates :requirement_type, presence: true

  validates :min_transactions_count,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            if: -> { min_transactions? || min_transactions_with_amount? }

  validates :min_amount_per_transaction,
            presence: true,
            numericality: { greater_than: 0 },
            if: :min_transactions_with_amount?

  validates :min_accumulated_amount,
            presence: true,
            numericality: { greater_than: 0 },
            if: :accumulated_amount?

  validates :monthly_fee_amount,
            presence: true,
            numericality: { greater_than: 0 },
            if: :monthly_fee?

  scope :active, -> { where(active: true) }
end
