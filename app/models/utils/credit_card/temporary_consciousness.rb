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

      def current_cycle
        today = Date.current
        cutting_date = if today.day >= cutting_day.to_i
                         (today + 1.month).change(day: cutting_day.to_i)
                       else
                         Date.new(today.year, today.month, cutting_day.to_i)
                       end
        find_or_create_cycle_by_cutting_date(cutting_date)
      end

      def last_month_cycle
        today = Date.current
        cutting_date = if today.day >= cutting_day.to_i
                         Date.new(today.year, today.month, cutting_day.to_i)
                       else
                         (today - 1.month).change(day: cutting_day.to_i)
                       end
        find_cycle_by_cutting_date(cutting_date)
      end

      # Métodos de consulta principales
      def total_debt
        credit_card_cycles.sum(:closing_balance)
      end

      def current_debt
        current_cycle&.closing_balance || 0.0
      end

      def available_credit
        limit_amount - total_debt
      end

      def utilization_percentage
        return 0 if limit_amount.zero?

        (total_debt / limit_amount * 100).round(2)
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
