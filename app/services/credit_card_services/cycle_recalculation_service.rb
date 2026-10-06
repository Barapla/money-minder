# frozen_string_literal: true

module CreditCardServices
  # Busca o crea el ciclo de una tarjeta para una fecha de corte dada y mantiene
  # su status al dia. El status sale del calendario del ciclo (ver
  # CreditCardCycle#lifecycle_status_code), no de sumar transacciones sueltas.
  class CycleRecalculationService
    attr_reader :credit_card

    def initialize(credit_card)
      @credit_card = credit_card
    end

    def find_or_create_cycle_for_date(cutting_date)
      cycle = credit_card.credit_card_cycles.find_or_create_by(cutting_date:) do |new_cycle|
        initialize_cycle(new_cycle, cutting_date)
      end
      refresh_status(cycle)
      cycle
    end

    private

    ZEROED_AMOUNTS = { cycle_balance: 0, purchases: 0, payments: 0,
                       fees: 0.0, minimum_payment: 0, interest: 0.0 }.freeze

    def initialize_cycle(cycle, cutting_date)
      cycle.assign_attributes(ZEROED_AMOUNTS)
      cycle.payment_due_date = cutting_date + credit_card.payment_due_days.to_i.days
      cycle.historical_balance = carried_balance_for(cycle)
      cycle.status = status_for(cycle)
    end

    # Lo que quedo debiendo el ciclo anterior se arrastra a este.
    def carried_balance_for(cycle)
      cycle.previous_cycle&.closing_balance || credit_card.initial_debt || 0.0
    end

    def refresh_status(cycle)
      status = status_for(cycle)
      cycle.update(status:) if status && cycle.status_id != status.id
    end

    def status_for(cycle)
      Status.find_by(code: cycle.lifecycle_status_code)
    end
  end
end
