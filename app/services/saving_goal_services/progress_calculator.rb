# frozen_string_literal: true

module SavingGoalServices
  # Calcula el progreso de una meta de ahorro basado en los saldos actuales del usuario.
  # Memoiza total_available_money para evitar N queries al calcular multiples metas.
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

    private

    attr_reader :user

    def total_available_money
      @total_available_money ||= cash_balance + debit_balance + savings_balance - credit_debt
    end

    def cash_balance
      user.budgets.where(personal: true, active: true).sum(:current_amount)
    end

    def debit_balance
      user.budgets
          .joins(:budget_type)
          .where(budgets: { active: true })
          .where(catalogs: { code: 'debit_card' })
          .sum(:current_amount)
    end

    def savings_balance
      SavingsFund.joins(:budget)
                 .where(budgets: { user_id: user.id, active: true })
                 .where(active: true)
                 .sum('budgets.current_amount')
    end

    def credit_debt
      ids = active_credit_card_ids
      return 0.0 if ids.empty?

      today = Date.current
      current_cycles_for(ids, today).sum(:closing_balance)
    end

    def current_cycles_for(ids, today)
      CreditCardCycle.where(credit_card_id: ids)
                     .where('cutting_date >= ?', today)
                     .where(no_earlier_cycle_sql, today)
    end

    def no_earlier_cycle_sql
      'NOT EXISTS (' \
        'SELECT 1 FROM credit_card_cycles c2 ' \
        'WHERE c2.credit_card_id = credit_card_cycles.credit_card_id ' \
        'AND c2.cutting_date >= ? ' \
        'AND c2.cutting_date < credit_card_cycles.cutting_date)'
    end

    def active_credit_card_ids
      user.budgets
          .joins(:credit_card)
          .where(credit_cards: { active: true })
          .pluck('credit_cards.id')
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
