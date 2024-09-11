# frozen_string_literal: true

# CreateCurrencies Class
class CreateCurrencies < ActiveRecord::Migration[7.0]
  def change
    create_table :currencies do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.string :name
      t.string :code
      t.string :symbol
      t.decimal :exchange_rate

      t.timestamps
    end

    add_index :currencies, :uuid, unique: true
  end
end