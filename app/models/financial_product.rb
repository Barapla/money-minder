# frozen_string_literal: true

# Producto financiero ofrecido por una institución (debito, credito, efectivo, ahorro).
class FinancialProduct < ApplicationRecord
  belongs_to :financial_institution
  has_many :benefits, class_name: 'FinancialProductBenefit', dependent: :destroy

  enum :product_type, { cash: 0, debit: 1, credit: 2, savings_fund: 3 }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :name, uniqueness: { scope: :financial_institution_id,
                                 case_sensitive: false,
                                 message: :taken }
  validates :product_type, presence: true
  validates :financial_institution, presence: true

  before_validation :strip_name

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_institution, ->(institution_id) { where(financial_institution_id: institution_id) }
  scope :by_type, ->(type) { where(product_type: type) }
  scope :alphabetical, -> { order(Arel.sql('LOWER(name)')) }

  private

  def strip_name
    self.name = name&.strip
  end
end
