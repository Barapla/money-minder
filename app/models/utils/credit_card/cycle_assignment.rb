# frozen_string_literal: true

# app/models/utils/credit_card/cycle_assignment.rb
module Utils
  module CreditCard
    # Decide a que ciclo pertenece cada transaccion.
    #
    # Un ciclo con corte D vive dos periodos y ambos pueden estar activos a la vez:
    #
    #   (D-1mes, D]        corriendo    — recibe las compras; los pagos de aqui
    #                                     aligeran el saldo que se va a cortar
    #   (D, D+due_days]    por pagar    — ya no recibe compras (esas van al ciclo
    #                                     siguiente, que ya arranco); solo recibe
    #                                     los pagos del estado de cuenta cortado
    module CycleAssignment
      extend ActiveSupport::Concern

      def determine_cycle_for_transaction(transaction)
        cutting_date = determine_cycle_cutting_date_for_transaction(transaction)
        ::CreditCardServices::CycleRecalculationService.new(self).find_or_create_cycle_for_date(cutting_date)
      end

      def determine_cycle_cutting_date_for_transaction(transaction)
        date = transaction.transaction_date.to_date
        case transaction.transaction_type.code
        when 'expense' then determine_cycle_for_expense(date)
        when 'income' then determine_cycle_for_payment(date)
        else raise "Unsupported transaction type: #{transaction.transaction_type.code}"
        end
      end

      # Una compra pertenece al ciclo que cierra en el proximo corte. El dia del
      # corte todavia entra en ese corte: el estado de cuenta de Santander abarca
      # "04-Ago al 03-Sep" e incluye los cargos del mismo 03-Sep.
      def determine_cycle_for_expense(date)
        date.day <= cutting_day ? clamped_cutting_date(date) : clamped_cutting_date(date >> 1)
      end

      # Un pago dentro de la ventana de pago liquida el corte que acaba de cerrar,
      # pero solo si a ese corte le queda saldo por cubrir. Un corte ya saldado (o
      # en cero) no recibe abonos: el dinero pasa al ciclo que esta corriendo, que
      # es tambien donde cae el sobrante de un pago fuera de ventana.
      def determine_cycle_for_payment(date)
        last_cut = last_cutting_date_on_or_before(date)
        return last_cut if within_payment_window?(date, last_cut) && outstanding_statement?(last_cut)

        determine_cycle_for_expense(date)
      end

      private

      def within_payment_window?(date, last_cut)
        date <= last_cut + payment_due_days.to_i.days
      end

      def outstanding_statement?(cutting_date)
        cycle = credit_card_cycles.find_by(cutting_date:)
        return false unless cycle

        (cycle.statement_balance - cycle.payments_after_cut).positive?
      end

      def last_cutting_date_on_or_before(date)
        date.day >= cutting_day ? clamped_cutting_date(date) : clamped_cutting_date(date << 1)
      end

      # Limita el dia al ultimo del mes para no construir fechas invalidas (31 de febrero).
      def clamped_cutting_date(base_date)
        Date.new(base_date.year, base_date.month, [cutting_day.to_i, base_date.end_of_month.day].min)
      end
    end
  end
end
