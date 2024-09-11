# frozen_string_literal: true

# Category model
class Category < ApplicationRecord
  belongs_to :parent_category, class_name: 'Category', optional: true
  has_many :sub_categories, class_name: 'Category', foreign_key: 'parent_category_id'
  has_many :transactions, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
