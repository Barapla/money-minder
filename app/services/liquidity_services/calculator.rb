# frozen_string_literal: true

module LiquidityServices
  # Calcula la liquidez disponible de un usuario: efectivo + debito + fondos de
  # ahorro - deuda de tarjetas de credito - capital bloqueado en TermSavings activos.
  # Compartido por SavingGoalServices::ProgressCalculator y ChatbotServices::LiquidityCalculator
  # para no duplicar las queries de balance (FEAT-010, FEAT-031).
  class Calculator
    def initialize(user)
      @user = user
    end

    def total_available_money
      @total_available_money ||=
        cash_balance + debit_balance + savings_balance - credit_debt - locked_term_savings_balance
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

    # Capital bloqueado en TermSavings activos que aun no vencen: no cuenta como
    # disponible (FEAT-024). Los vencidos o retirados ya suman via savings_balance
    # (el dinero vuelve al saldo del budget al madurar).
    def locked_term_savings_balance
      TermSaving.joins(:budget)
                .where(budgets: { user_id: user.id, active: true })
                .active
                .where('matures_at > ?', Date.current)
                .sum(:principal_amount)
    end

    def credit_debt
      ids = active_credit_card_ids
      return 0.0 if ids.empty?

      today = Date.current
      current_cycles_for(ids, today).sum(:closing_balance)
    end

    private

    attr_reader :user

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
  end
end
