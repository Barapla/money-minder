class ObligatoryPayment < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  has_one :recurrence, as: :recurrenceable, dependent: :destroy

  # Accept nested attributes for recurrence
  accepts_nested_attributes_for :recurrence, allow_destroy: true

  # Quitas due_day de este modelo
  validates :name, :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }

  def next_occurrence_from(date = Date.current)
    rec = get_recurrence
    rec&.next_occurrence_from(date)
  end

  def next_due_date
    rec = get_recurrence
    rec&.next_occurrence_from || nil
  end

  def get_recurrence
    Recurrence.find_by(
      recurrenceable_type: 'ObligatoryPayment',
      recurrenceable_id: id
    )
  end
end
