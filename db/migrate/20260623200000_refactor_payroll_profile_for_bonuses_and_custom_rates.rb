# frozen_string_literal: true

# Agrega columnas para sueldo base gravado, bonos no gravados y tasas configurables de ISR/IMSS.
class RefactorPayrollProfileForBonusesAndCustomRates < ActiveRecord::Migration[7.2]
  def change
    add_new_columns
    backfill_base_salary
  end

  private

  def add_new_columns
    add_column :payroll_profiles, :base_salary, :decimal, precision: 10, scale: 2
    add_column :payroll_profiles, :non_taxable_bonuses, :jsonb, default: {}
    add_column :payroll_profiles, :custom_isr_rate, :decimal, precision: 5, scale: 2
    add_column :payroll_profiles, :custom_imss_rate, :decimal, precision: 5, scale: 2
    add_column :payroll_profiles, :savings_fund_rate, :decimal, precision: 5, scale: 2, default: 4.0
  end

  def backfill_base_salary
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE payroll_profiles
          SET base_salary = monthly_gross_salary
          WHERE monthly_gross_salary IS NOT NULL
        SQL
      end
    end
  end
end
