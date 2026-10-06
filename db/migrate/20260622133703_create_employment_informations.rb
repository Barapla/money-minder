# frozen_string_literal: true

class CreateEmploymentInformations < ActiveRecord::Migration[7.2]
  def change
    create_table :employment_informations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_title, null: false
      t.date :start_date, null: false
      t.decimal :gross_salary_amount, precision: 15, scale: 2, null: false
      t.string :salary_periodicity, null: false

      t.timestamps
    end

    add_index :employment_informations, %i[user_id start_date]
  end
end
