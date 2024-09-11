# frozen_string_literal: true

# Currency model
class Currency < ApplicationRecord
  has_many :transactions, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true
  validates :symbol, presence: true
end
