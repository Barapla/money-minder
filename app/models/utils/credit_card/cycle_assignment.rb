# frozen_string_literal: true

# app/models/utils/credit_card/cycle_assignment.rb
module Utils
  module CreditCard
    module CycleAssignment
      extend ActiveSupport::Concern

      def determine_cycle_for_transaction(transaction)
        cutting_date = determine_cycle_cutting_date_for_transaction(transaction)
        ::CreditCardServices::CycleRecalculationService.new(self).find_or_create_cycle_for_date(cutting_date)
      end

      def debug_cycle_assignment(transaction)
        date = transaction.transaction_date
        type = transaction.transaction_type.code
        result = determine_cycle_cutting_date_for_transaction(transaction)

        puts "Transaction: #{type} on #{date}"
        puts "Assigned to cycle: #{result}"
        puts "Cutting day: #{cutting_day}"
        puts "Payment due days: #{payment_due_days}"
        puts '---'

        result
      end

      def determine_cycle_cutting_date_for_transaction(transaction)
        date = transaction.transaction_date
        transaction_type = transaction.transaction_type.code
        case transaction_type
        when 'expense'
          determine_cycle_for_expense(date)
        when 'income'
          determine_cycle_for_payment(date)
        else
          raise "Unsupported transaction type: #{transaction_type}"
        end
      end

      private

      # ==========================================
      # MÉTODOS PARA GASTOS/COMPRAS
      # ==========================================

      def determine_cycle_for_expense(transaction_date)
        if transaction_before_cutting_day?(transaction_date)
          cutting_date_for_current_cycle(transaction_date)
        else
          cutting_date_for_next_cycle(transaction_date)
        end
      end

      def transaction_before_cutting_day?(date)
        date.day < cutting_day
      end

      def cutting_date_for_current_cycle(date)
        Date.new(date.year, date.month, cutting_day)
      end

      def cutting_date_for_next_cycle(date)
        next_month = date.beginning_of_month + 1.month
        Date.new(next_month.year, next_month.month, cutting_day)
      end

      # ==========================================
      # MÉTODOS PARA PAGOS/INGRESOS
      # ==========================================

      def determine_cycle_for_payment(payment_date)
        if payment_date.day <= cutting_day
          handle_payment_before_or_on_cutting_day(payment_date)
        else
          handle_payment_after_cutting_day(payment_date)
        end
      end

      # ==========================================
      # PAGOS ANTES O EN EL DÍA DE CORTE
      # ==========================================

      def handle_payment_before_or_on_cutting_day(payment_date)
        # Calcular la fecha de vencimiento del ciclo actual
        current_cycle_due_date = Date.new(payment_date.year, payment_date.month, cutting_day) + payment_due_days.days

        if payment_crosses_month_boundary?(current_cycle_due_date, payment_date)
          handle_cross_month_payment_scenario_1(payment_date, current_cycle_due_date)
        else
          # Pago normal dentro del mismo mes
          Date.new(payment_date.year, payment_date.month, cutting_day)
        end
      end

      def handle_cross_month_payment_scenario_1(payment_date, current_cycle_due_date)
        # Ajustar la fecha de vencimiento al mes anterior
        prev_month = current_cycle_due_date.beginning_of_month - 1.day
        adjusted_due_date = Date.new(prev_month.year, prev_month.month, current_cycle_due_date.day)

        if payment_date.day < adjusted_due_date.day
          # Verificar estado del ciclo anterior
          prev_cycle_cutting_date = Date.new(prev_month.year, prev_month.month, cutting_day)
          prev_cycle = find_cycle_by_cutting_date(prev_cycle_cutting_date)

          decide_cycle_for_early_payment(payment_date, prev_cycle, prev_cycle_cutting_date)
        else
          # Pago después del vencimiento anterior, va al ciclo actual
          Date.new(payment_date.year, payment_date.month, cutting_day)
        end
      end

      def decide_cycle_for_early_payment(payment_date, prev_cycle, prev_cycle_cutting_date)
        case prev_cycle&.status&.code
        when 'closed'
          Date.new(payment_date.year, payment_date.month, cutting_day)
        when 'pending_payment', 'overdue'
          prev_cycle_cutting_date
        else
          # Estado desconocido o ciclo inexistente, defaultear al actual
          Date.new(payment_date.year, payment_date.month, cutting_day)
        end
      end

      # ==========================================
      # PAGOS DESPUÉS DEL DÍA DE CORTE
      # ==========================================

      def handle_payment_after_cutting_day(payment_date)
        current_cycle_due_date = Date.new(payment_date.year, payment_date.month, cutting_day) + payment_due_days.days

        if should_check_current_cycle_status?(current_cycle_due_date, payment_date)
          handle_payment_with_cycle_status_check(payment_date)
        else
          # Va al siguiente ciclo
          next_cycle_month = payment_date.beginning_of_month + 1.month
          Date.new(next_cycle_month.year, next_cycle_month.month, cutting_day)
        end
      end

      def should_check_current_cycle_status?(due_date, payment_date)
        due_date.month != payment_date.month || payment_date.day < due_date.day
      end

      def handle_payment_with_cycle_status_check(payment_date)
        current_cycle_cutting_date = Date.new(payment_date.year, payment_date.month, cutting_day)
        current_cycle = find_or_create_cycle_by_cutting_date(current_cycle_cutting_date)

        case current_cycle&.status&.code
        when 'closed'
          # Ciclo cerrado, va al siguiente
          next_cycle_month = payment_date.beginning_of_month + 1.month
          Date.new(next_cycle_month.year, next_cycle_month.month, cutting_day)
        when 'pending_payment', 'overdue'
          # Ciclo pendiente de pago, el pago va ahí
          current_cycle_cutting_date
        else
          # Estado desconocido, defaultear al siguiente ciclo
          next_cycle_month = payment_date.beginning_of_month + 1.month
          Date.new(next_cycle_month.year, next_cycle_month.month, cutting_day)
        end
      end

      # ==========================================
      # MÉTODOS DE UTILIDAD
      # ==========================================

      def payment_crosses_month_boundary?(due_date, payment_date)
        due_date.month != payment_date.month
      end
    end
  end
end
