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

  belongs_to :user
  belongs_to :budget_type, class_name: 'Catalog', foreign_key: 'budget_type_id'
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  accepts_nested_attributes_for :credit_card

  # Construir credit_card automáticamente
  after_initialize :build_credit_card_if_needed

  def budget_color
    self.class.progress_color(current_amount, limit_amount)
  end

  def budget_percentage
    self.class.progress_percentage(current_amount, limit_amount)
  end

  def budget_status
    self.class.progress_status(current_amount, limit_amount)
  end

  private

  def build_credit_card_if_needed
    # Para registros nuevos, siempre construir credit_card
    # Para registros existentes, solo si es credit_card y no existe
    if new_record?
      build_credit_card if credit_card.nil?
    elsif credit_card.nil? && budget_type&.code == 'credit_card'
      build_credit_card
    end
  end
end
