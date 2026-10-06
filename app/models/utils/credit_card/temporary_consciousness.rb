# frozen_string_literal: true

# app/utils/credit_card/temporary_consciousness.rb
module Utils
  module CreditCard
    # Temporary module to add consciousness of cycles to CreditCard model
    module TemporaryConsciousness
      extend ActiveSupport::Concern
      # Incluir el módulo de asignación de ciclos
      include Utils::CreditCard::CycleAssignment

      def process_transaction(transaction)
        # Usar CycleAssignment para determinar el ciclo correcto
        cutting_date = determine_cycle_cutting_date_for_transaction(transaction)
        target_cycle = find_or_create_cycle_by_cutting_date(cutting_date)

        case transaction.transaction_type.code
        when 'income'
          target_cycle.process_payment(transaction)
        when 'expense'
          target_cycle.process_purchase(transaction)
        end

        # create_history_entry(transaction, target_cycle)
      end

      # Ciclo que esta acumulando hoy. El dia del corte todavia pertenece a ese
      # corte, asi que solo a partir del dia siguiente se pasa al del mes que viene.
      def current_cycle
        today = Date.current
        base = today.day > cutting_day.to_i ? today >> 1 : today
        find_or_create_cycle_by_cutting_date(clamped_cutting_date(base))
      end

      def last_month_cycle
        today = Date.current
        base = today.day > cutting_day.to_i ? today : today << 1
        find_cycle_by_cutting_date(clamped_cutting_date(base))
      end

      # Deuda vigente de la tarjeta. `closing_balance` es un saldo corrido
      # (cycle_balance + historical_balance) que se arrastra al siguiente ciclo,
      # asi que sumarlo entre ciclos cuenta la misma deuda varias veces: el saldo
      # del ciclo en curso ya incluye todo lo que se debe.
      def current_debt
        current_cycle&.closing_balance || 0.0
      end

      def available_credit
        limit_amount - current_debt
      end

      def utilization_percentage
        return 0 if limit_amount.zero?

        (current_debt / limit_amount * 100).round(2)
      end

      # Método directo - ya no recalcula cutting_date si ya lo tienes
      def find_or_create_cycle_by_cutting_date(cutting_date)
        ::CreditCardServices::CycleRecalculationService.new(self).find_or_create_cycle_for_date(cutting_date)
      end

      private

      # Método para cuando SÍ necesitas calcular la fecha de corte
      def find_cycle_by_cutting_date(cutting_date)
        credit_card_cycles.find_by(cutting_date:)
      end

      def create_history_entry(transaction, cycle)
        # Crear historial si necesitas tracking
        # credit_card_histories.create!(...)
      end
    end
  end
end
