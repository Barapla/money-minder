# frozen_string_literal: true

# Budget Model
class Budget < ApplicationRecord
  include ProgressColorIndicator

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :current_amount, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :limit_amount, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :budget_type_id, presence: true
  validates :color_id, presence: true
  validates :icon_id, presence: true

  # Associations
  has_many :transactions, dependent: :destroy

  belongs_to :budget_type, class_name: 'Catalog', foreign_key: 'budget_type_id'
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  def budget_color
    self.class.progress_color(current_amount, limit_amount)
  end

  def budget_percentage
    self.class.progress_percentage(current_amount, limit_amount)
  end

  def budget_status
    self.class.progress_status(current_amount, limit_amount)
  end
end
