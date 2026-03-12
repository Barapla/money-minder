# frozen_string_literal: true

# CreateCreditCardProducts Class
class CreateCreditCardProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_card_products do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :financial_institution, null: false, foreign_key: { to_table: :financial_institutions, name: 'fk_credit_card_products_financial_institution' }
      t.references :credit_card_tier, null: false, foreign_key: { to_table: :credit_card_tiers, name: 'fk_credit_card_products_credit_card_tier' }
      
      # Identificación
      t.string :name, null: false
      t.string :code, null: false, index: { unique: true }

      # Configuración de ciclos
      t.references :cycle_calculation_type, null: false, foreign_key: { to_table: :catalogs, name: 'fk_credit_card_products_cycle_calculation_type' }
      t.integer :default_cutting_day # 1-31, solo para fixed_day
      t.integer :cycle_days # 30 para Plata, null para fixed_day
      t.integer :payment_grace_days, null: false # días entre corte y pago
      
      # Configuración financiera
      t.decimal :default_interest_rate, precision: 5, scale: 2
      t.integer :minimum_payment_calculation, default: 0 # enum: percentage, fixed, custom
      t.decimal :minimum_payment_value, precision: 10, scale: 2
      t.decimal :annual_fee, precision: 10, scale: 2, default: 0
      t.boolean :reports_to_buro, default: true
      
      # Metadata
      t.jsonb :benefits, default: {}
      t.string :reward_type # cashback, points, miles

      t.timestamps
    end

    add_index :credit_card_products, :uuid, unique: true
  end
end