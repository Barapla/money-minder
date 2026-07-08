# frozen_string_literal: true

# Catalogo global de instituciones financieras administrable por admins.
class FinancialInstitution < ApplicationRecord
  has_many :financial_products, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false },
                   length: { minimum: 2 }

  before_validation :strip_and_generate_code

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :alphabetical, -> { order(Arel.sql('LOWER(name)')) }

  private

  def strip_and_generate_code
    self.name = name&.strip
    self.code = name&.parameterize if code.blank? && name.present?
  end
end
