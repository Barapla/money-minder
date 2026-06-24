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

    # Suma closing_balance del ciclo vigente (minimo cutting_date >= hoy) por tarjeta activa.
    # Usa subconsulta correlacionada para evitar N+1 sin interpolacion de variables en SQL.
    CURRENT_CYCLE_SQL = <<~SQL.squish.freeze
      NOT EXISTS (
        SELECT 1 FROM credit_card_cycles c2
        WHERE c2.credit_card_id = credit_card_cycles.credit_card_id
        AND c2.cutting_date >= ?
        AND c2.cutting_date < credit_card_cycles.cutting_date
      )
    SQL

    def credit_card_debt
      ids = active_credit_card_ids
      return 0.0 if ids.empty?

      today = Date.current
      CreditCardCycle.where(credit_card_id: ids)
                     .where('cutting_date >= ?', today)
                     .where(CURRENT_CYCLE_SQL, today)
                     .sum(:closing_balance)
    end

    def active_credit_card_ids
      user.budgets
          .joins(:credit_card)
          .where(credit_cards: { active: true })
          .pluck('credit_cards.id')
    end
  end
end
