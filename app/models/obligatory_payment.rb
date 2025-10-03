class ObligatoryPayment < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  has_one :recurrence, as: :recurrenceable, dependent: :destroy

  # Quitas due_day de este modelo
  validates :name, :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }

  delegate :next_occurrence_from, to: :recurrence

  def next_due_date
    recurrence&.next_occurrence_from || nil
  end
end
