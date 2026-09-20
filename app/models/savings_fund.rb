# frozen_string_literal: true

# This class represents a savings fund in the application.
class SavingsFund < ApplicationRecord
  include FinancialProductAssociable

  belongs_to :budget

  # Usar las transacciones para calcular el saldo
  def closing_balance
    budget.current_amount
  end

  # La tasa se captura como porcentaje anual (el campo trae sufijo "%"), asi que
  # hay que bajarla a fraccion antes de usarla: 15.0 es 15%, no 1500%.
  def monthly_rate
    (interest_rate || 0).to_f / 100 / 12
  end

  # Proyección de saldo futuro
  def projected_balance_in_months(months)
    rate_monthly = monthly_rate
    current = closing_balance
    monthly = monthly_contribution || 0

    # Interés compuesto con aportes mensuales
    future_value_current = current * ((1 + rate_monthly)**months)
    future_value_contributions = monthly * (((1 + rate_monthly)**months - 1) / rate_monthly) if rate_monthly > 0
    future_value_contributions ||= monthly * months

    future_value_current + future_value_contributions
  end

  # Tiempo para alcanzar la meta
  def months_to_reach_goal
    return 0 if (goal_amount || 0) <= closing_balance
    return nil if (monthly_contribution || 0) <= 0

    rate_monthly = monthly_rate
    remaining = goal_amount - closing_balance
    monthly = monthly_contribution

    if rate_monthly.positive?
      Math.log((goal_amount * rate_monthly + monthly) /
               (closing_balance * rate_monthly + monthly)) /
        Math.log(1 + rate_monthly)
    else
      remaining / monthly
    end
  end

  # Progreso hacia la meta
  def progress_percentage
    return 0 if (goal_amount || 0) <= 0

    [(closing_balance / goal_amount * 100), 100].min
  end

  # Sugerencia de aporte mensual para alcanzar meta
  def suggested_monthly_contribution
    return 0 unless target_date && goal_amount && goal_amount > closing_balance

    months_available = ((target_date - Date.current) / 30.44).to_i
    return 0 if months_available <= 0

    remaining_amount = goal_amount - closing_balance
    rate_monthly = monthly_rate

    if rate_monthly.positive?
      future_value_current = closing_balance * ((1 + rate_monthly)**months_available)
      remaining_after_interest = goal_amount - future_value_current

      remaining_after_interest / (((1 + rate_monthly)**months_available - 1) / rate_monthly)
    else
      remaining_amount / months_available
    end
  end

  # Análisis de viabilidad
  def goal_feasibility
    months_needed = months_to_reach_goal
    months_available = target_date ? ((target_date - Date.current) / 30.44).to_i : nil

    return 'no_target_date' unless months_available
    return 'impossible' unless months_needed

    if months_needed <= months_available * 0.8
      'easily_achievable'
    elsif months_needed <= months_available
      'achievable'
    elsif months_needed <= months_available * 1.2
      'challenging'
    else
      'unrealistic'
    end
  end
end
