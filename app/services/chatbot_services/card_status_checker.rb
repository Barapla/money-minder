# frozen_string_literal: true

module ChatbotServices
  # Estado del ciclo vigente de una tarjeta de credito, localizada por nombre
  # dentro del mensaje del usuario (ej. "mi ciclo de Banamex" -> budget.name).
  class CardStatusChecker
    def initialize(user:, message:)
      @user = user
      @message = message.to_s.downcase
    end

    def calculate
      budget = matching_card_budget
      return not_found_result if budget.nil?

      Result.success(data: {
                       result: card_result(budget),
                       assumptions: ['Los datos corresponden al ciclo actualmente abierto de la tarjeta.'],
                       warnings: []
                     })
    end

    private

    attr_reader :user, :message

    def card_result(budget)
      card = budget.credit_card
      cycle = card.current_cycle
      { primary_metric: cycle.closing_balance.to_f, breakdown: card_breakdown(budget, card, cycle) }
    end

    def card_breakdown(budget, card, cycle)
      [
        { label: 'Tarjeta', amount: budget.name },
        { label: 'Límite de crédito', amount: card.limit_amount.to_f },
        { label: 'Saldo actual del ciclo', amount: cycle.closing_balance.to_f },
        { label: 'Próxima fecha de corte', amount: cycle.next_cutting_date.strftime('%d/%m/%Y') },
        { label: 'Días hasta el pago', amount: cycle.days_until_due }
      ]
    end

    def credit_card_budgets
      user.budgets.joins(:credit_card).where(budgets: { active: true })
    end

    def matching_card_budget
      match = credit_card_budgets.where("? ILIKE ('%' || budgets.name || '%')", message).first
      return match if match

      credit_card_budgets.count == 1 ? credit_card_budgets.first : nil
    end

    def not_found_result
      Result.failure(
        error: :card_not_found,
        message: 'No encontramos una tarjeta que coincida con tu mensaje. Especifica el nombre exacto de la tarjeta.'
      )
    end
  end
end
