# frozen_string_literal: true

class CreatePayrollProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :payroll_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.decimal :monthly_gross_salary, precision: 12, scale: 2, null: false
      t.date :hire_date, null: false
      t.decimal :savings_fund_percentage, precision: 5, scale: 2, default: 13.0, null: false

      t.timestamps
    end
  end
end
