class ObligatoryPayment < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :color, class_name: 'Catalog', foreign_key: 'color_id'
  belongs_to :icon, class_name: 'Catalog', foreign_key: 'icon_id'

  has_one :recurrence, as: :recurrenceable, dependent: :destroy

  # Accept nested attributes for recurrence
  accepts_nested_attributes_for :recurrence, allow_destroy: true

  enum :reminder_type, { payment: 'payment', income: 'income' }, default: :payment

  scope :one_time, -> { left_joins(:recurrence).where(recurrences: { id: nil }) }
  scope :recurring, -> { left_joins(:recurrence).where.not(recurrences: { id: nil }) }
  scope :by_type, ->(type) { type.present? ? where(reminder_type: type) : all }

  # Quitas due_day de este modelo
  validates :name, presence: true
  validates :amount, numericality: { greater_than: 0 }, if: -> { amount.present? }
  validates :due_date, presence: true, if: :one_time?

  # Sin Recurrence asociada: el recordatorio ocurre una sola vez, en due_date.
  def one_time?
    recurrence.blank? || recurrence.marked_for_destruction?
  end

  def recurring?
    !one_time?
  end

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
