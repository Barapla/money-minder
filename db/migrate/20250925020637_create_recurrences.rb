# frozen_string_literal: true

# CreateRecurrences Class
class CreateRecurrences < ActiveRecord::Migration[7.0]
  def change
    create_table :recurrences do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :recurrenceable_type, null: false, foreign_key: { to_table: :catalogs, name: 'fk_recurrences_recurrenceable_type' }
      t.references :recurrenceable, polymorphic: true, null: true, index: true
      t.references :frequency_type, null: false, foreign_key: { to_table: :catalogs, name: 'fk_recurrences_frequency_type' }
      t.integer :frequency_value
      t.integer :day_of_week
      t.integer :day_of_month
      t.integer :month_of_year
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    add_index :recurrences, :uuid, unique: true
  end
end
