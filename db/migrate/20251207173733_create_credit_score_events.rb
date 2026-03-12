# frozen_string_literal: true

# CreateCreditScoreEvents Class
class CreateCreditScoreEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_score_events do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :credit_card, null: false, foreign_key: { to_table: :credit_cards, name: 'fk_credit_score_events_credit_card' }
      t.references :credit_card_cycle, null: false, foreign_key: { to_table: :credit_card_cycles, name: 'fk_credit_score_events_credit_card_cycle' }
      
       # Tipo de evento
      t.integer :event_type, null: false # enum
      # payment_on_time, payment_late_1_5_days, payment_late_5_plus_days,
      # payment_full, payment_above_minimum, payment_minimum_only, payment_below_minimum,
      # utilization_under_10, utilization_10_30, utilization_30_50, utilization_50_80, utilization_over_80
      
      # Impacto
      t.integer :impact, null: false # enum: excellent, good, neutral, bad, terrible
      
      # Metadata
      t.date :event_date, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.text :notes
      t.boolean :auto_generated, default: false
      
      t.timestamps
    end

    add_index :credit_score_events, :uuid, unique: true
    add_index :credit_score_events, :event_type
    add_index :credit_score_events, :impact
    add_index :credit_score_events, :event_date
    add_index :credit_score_events, [:credit_card_id, :event_date]
  end
end