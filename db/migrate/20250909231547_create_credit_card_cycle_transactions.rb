# frozen_string_literal: true

# CreateCreditCardCycleTransactions Class
class CreateCreditCardCycleTransactions < ActiveRecord::Migration[7.0]
  def up
    create_table :credit_card_cycle_transactions do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.references :transaction, null: false, foreign_key: { to_table: :transactions, name: 'fk_ccct_transactions' }
      t.references :credit_card_cycle, null: false,
                                       foreign_key: { to_table: :credit_card_cycles,
                                                      name: 'fk_ccct_credit_card_cycles' }

      t.timestamps
    end

    add_index :credit_card_cycle_transactions, :uuid, unique: true
  end

  def down
    drop_table :credit_card_cycle_transactions
  end
end
