# frozen_string_literal: true

# Agrega restriccion NOT NULL a base_salary despues de garantizar que todos los registros tienen valor.
class AddNotNullConstraintToPayrollProfilesBaseSalary < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      UPDATE payroll_profiles
      SET base_salary = monthly_gross_salary
      WHERE base_salary IS NULL AND monthly_gross_salary IS NOT NULL
    SQL

    change_column_null :payroll_profiles, :base_salary, false
  end

  def down
    change_column_null :payroll_profiles, :base_salary, true
  end
end
