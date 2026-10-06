# frozen_string_literal: true

module CreditCardCycles
  # Reconstruye los ciclos de una tarjeta desde sus transacciones, que son la
  # fuente de verdad: pone los contadores en cero y vuelve a procesar cada
  # transaccion en orden de fecha con la regla vigente de asignacion de ciclos.
  # Idempotente: correrlo dos veces da el mismo resultado.
  class Recalculator
    def self.cards_for(budget_id)
      scope = CreditCard.joins(:budget).includes(:budget)
      budget_id.present? ? scope.where(budget_id:) : scope
    end

    def initialize(credit_card)
      @credit_card = credit_card
    end

    def call
      ActiveRecord::Base.transaction do
        reset_cycles!
        replay_transactions!
      end
      { transactions: transactions.size, cycles: credit_card.credit_card_cycles.count,
        cycles_detail: cycles_detail }
    end

    private

    attr_reader :credit_card

    def transactions
      @transactions ||= credit_card.budget
                                   .transactions
                                   .includes(:transaction_type)
                                   .order(:transaction_date, :id)
                                   .to_a
    end

    # Los contadores se limpian sin callbacks para no disparar el arrastre de
    # saldos a medio camino; el replay los vuelve a construir en orden.
    def reset_cycles!
      CreditCardCycleTransaction.where(credit_card_cycle: credit_card.credit_card_cycles).delete_all
      ordered_cycles.each_with_index do |cycle, index|
        cycle.update_columns(purchases: 0, payments: 0, cycle_balance: 0, closing_balance: 0,
                             historical_balance: index.zero? ? credit_card.initial_debt.to_f : 0.0,
                             updated_at: Time.current)
      end
    end

    def replay_transactions!
      transactions.each do |transaction|
        cycle = credit_card.determine_cycle_for_transaction(transaction)
        cycle.process_transaction(transaction)
      end
      rechain_balances!
    end

    # Rehace la cadena de saldos en orden de corte: cada ciclo arrastra el cierre
    # del anterior y cierra en arrastre + su actividad. Se escribe sin callbacks
    # porque el encadenamiento ya va en orden; un ciclo sin transacciones tambien
    # tiene que recalcularse, si no pierde lo que trae arrastrado.
    def rechain_balances!
      service = ::CreditCardServices::CycleRecalculationService.new(credit_card)
      carried = credit_card.initial_debt.to_f
      ordered_cycles(reload: true).each do |cycle|
        closing = carried + cycle.cycle_balance.to_f
        cycle.update_columns(historical_balance: carried, closing_balance: closing, updated_at: Time.current)
        carried = closing
        service.find_or_create_cycle_for_date(cycle.cutting_date)
      end
    end

    def ordered_cycles(reload: false)
      @ordered_cycles = nil if reload
      @ordered_cycles ||= credit_card.credit_card_cycles.order(:cutting_date).to_a
    end

    def cycles_detail
      ordered_cycles(reload: true).map do |cycle|
        format('corte %<cut>s  compras %<purchases>9.2f  pagos %<payments>9.2f  ' \
               'cierre %<closing>9.2f  %<stage>s/%<behavior>s',
               cut: cycle.cutting_date, purchases: cycle.purchases, payments: cycle.payments,
               closing: cycle.closing_balance, stage: cycle.lifecycle_status_code,
               behavior: cycle.payment_behavior)
      end
    end
  end
end
