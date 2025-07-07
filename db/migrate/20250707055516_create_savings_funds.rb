# frozen_string_literal: true

# CreateSavingsFunds Class
class CreateSavingsFunds < ActiveRecord::Migration[7.0]
  def change
    create_table :savings_funds do |t|
      t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
      t.boolean :active, default: true
      t.decimal :goal_amount
      t.date :target_date
      t.decimal :monthly_contribution
      t.decimal :interest_rate
      t.references :compound_frequency, null: false,
                                        foreign_key: {
                                          to_table: :catalogs, name: 'fk_savings_funds_compound_frequency'
                                        }
      t.decimal :minimum_balance
      t.decimal :max_balance
      t.string :account_number
      t.references :account_type, null: false,
                                  foreign_key: { to_table: :catalogs, name: 'fk_savings_funds_account_type' }
      t.boolean :auto_transfer
      t.integer :transfer_day
      t.date :next_contribution_date
      t.decimal :early_withdrawal_penalty
      t.integer :withdrawal_limit
      t.boolean :has_withdrawal_restrictions
      t.date :maturity_date
      t.date :last_interest_payment
      t.decimal :low_balance_alert
      t.boolean :goal_milestone_alerts
      t.references :budget, null: false,
                            foreign_key: { to_table: :budgets, name: 'fk_savings_funds_budget' }

      t.timestamps
    end

    add_index :savings_funds, :uuid, unique: true
  end
end
