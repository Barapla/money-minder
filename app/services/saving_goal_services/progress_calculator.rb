# frozen_string_literal: true

module SavingGoalServices
  # Calcula el progreso de una meta de ahorro basado en los saldos actuales del usuario.
  # Memoiza el LiquidityServices::Calculator para evitar N queries al calcular multiples metas.
  class ProgressCalculator
    def initialize(user)
      @user = user
    end

    def calculate_for(goal)
      available = total_available_money
      percentage = calculate_percentage(available, goal.target_amount)

      {
        available_money: available,
        progress_percentage: percentage,
        days_remaining: days_remaining(goal.deadline),
        is_achieved: percentage >= 100
      }
    end

    def total_available_money
      liquidity.total_available_money
    end

    private

    attr_reader :user

    def liquidity
      @liquidity ||= LiquidityServices::Calculator.new(user)
    end

    def calculate_percentage(available, target)
      return 0 if target.zero?

      ((available / target) * 100).round(2)
    end

    def days_remaining(deadline)
      return nil unless deadline

      (deadline - Date.today).to_i
    end
  end
end
