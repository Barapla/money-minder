# frozen_string_literal: true

# CreateCreditCardTiers Class
class CreateCreditCardTiers < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_card_tiers do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :name
      t.integer :level # null para fintech, 1-5 para tradicionales
      t.decimal :recommended_utilization, precision: 5, scale: 2, null: false # porcentaje
      t.decimal :credit_score_weight, precision: 5, scale: 2, null: false, default: 1.0
      t.text :description

      t.timestamps
    end

    add_index :credit_card_tiers, :uuid, unique: true
    add_index :credit_card_tiers, :name, unique: true
    add_index :credit_card_tiers, :level
  end
end