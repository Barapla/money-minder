# frozen_string_literal: true

module SavingGoalServices
  # Distribuye el saldo disponible del usuario entre sus metas de ahorro activas
  # en orden de prioridad: llena la meta de mayor prioridad primero, luego la siguiente.
  # La asignación es solo visual/calculada — no modifica saldos en base de datos.
  class PriorityAllocator
    def initialize(user)
      @user = user
    end

    # Retorna hash { saving_goal_id => monto_asignado }
    def allocate
      allocations = {}
      remaining = available_balance

      active_goals_by_priority.each do |goal|
        break if remaining <= 0

        needed = goal.target_amount
        allocated = [remaining, needed].min
        allocations[goal.id] = allocated
        remaining -= allocated
      end

      allocations
    end

    private

    attr_reader :user

    def available_balance
      @available_balance ||= [cash_balance + debit_balance + savings_balance - credit_card_debt, 0].max
    end

    def active_goals_by_priority
      user.saving_goals.where(status: :active).order(:priority_order)
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

    def credit_card_debt
      user.budgets
          .joins(:credit_card)
          .where(credit_cards: { active: true })
          .includes(:credit_card)
          .sum { |b| b.credit_card&.current_debt.to_f }
    end
  end
end
