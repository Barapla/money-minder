# frozen_string_literal: true

# Calcula el progreso de cada fondo de ahorro activo hacia su meta (FEAT-038).
class SavingsSummaryCalculator
  def initialize(user)
    @user = user
  end

  def call
    savings_fund_budgets.map { |budget| entry_for(budget) }
  end

  private

  attr_reader :user

  def savings_fund_budgets
    user.budgets
        .joins(:savings_fund)
        .where(savings_funds: { active: true })
        .includes(:savings_fund)
  end

  def entry_for(budget)
    fund = budget.savings_fund

    { fund_id: fund.id,
      fund_name: budget.name,
      current_amount: fund.closing_balance.to_f,
      goal_amount: fund.goal_amount.to_f,
      percentage_achieved: fund.progress_percentage.to_f.round(2),
      target_date: fund.target_date,
      feasibility: fund.goal_feasibility }
  end
end
