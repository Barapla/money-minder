# frozen_string_literal: true

# Utils
module Utils
  # CreditCard module
  module CreditCard
    # TemporaryConsciousness module
    module TemporaryConsciousness
      extend ActiveSupport::Concern

        def current_cycle
          @current_cycle ||= find_or_create_cycle_for_date(Date.current)
        end

        def next_cycle
          @next_cycle ||= find_or_create_cycle_for_date(current_cycle.next_cutting_date)
        end

        def cycle_for_transaction_date(date)
          find_or_create_cycle_for_date(date)
        end

        # Responde: "¿Cuánto debo pagar exactamente en mi próximo vencimiento?"
        def amount_due_next_payment
          cycle = current_cycle
          return 0 if cycle.payment_due_date > Date.current

          cycle.statement_balance + cycle.interest_charges + cycle.fees
        end

        # Responde: "¿Esta transacción va al estado actual o al siguiente?"
        def which_cycle_for_transaction(transaction_date)
          cycle = cycle_for_transaction_date(transaction_date)
          {
            cycle: cycle,
            is_current: cycle == current_cycle,
            will_affect_next_payment: cycle.payment_due_date <= Date.current + 30.days
          }
        end

        # Responde: "¿Qué utilización va a reportar al Buró este mes?"
        def utilization_for_bureau_reporting(date = Date.current)
          cycle = find_cycle_by_cutting_date(date)
          return 0 if cycle.nil? || limit_amount.zero?

          (cycle.statement_balance / limit_amount * 100).round(2)
        end

        # Procesa una transacción con conciencia temporal
        def process_transaction(transaction)
          target_cycle = cycle_for_transaction_date(transaction.transaction_date)

          case transaction.transaction_type_id
          when income_transaction_type_id
            target_cycle.process_payment(transaction)
          when expense_transaction_type_id
            target_cycle.process_purchase(transaction)
          end

          # Actualizar balances generales
          recalculate_totals

          # Crear historial
          create_history_entry(transaction, target_cycle)
        end

        def total_debt
          credit_card_cycles.sum(:current_balance)
        end

        def available_credit
          limit_amount - total_debt
        end

        def utilization_percentage
          return 0 if limit_amount.zero?
          (total_debt / limit_amount * 100).round(2)
        end

        private

        def find_or_create_cycle_for_date(date)
          cutting_date = calculate_cutting_date_for(date)

          credit_card_cycles.find_or_create_by(cutting_date: cutting_date) do |cycle|
            cycle.payment_due_date = cutting_date + payment_due_days.days
            cycle.statement_balance = 0.0
            cycle.current_balance = 0.0
            cycle.minimum_payment = 0.0
            cycle.interest_charges = 0.0
            cycle.fees = 0.0
            cycle.status = Status.find_by(code: 'open')
          end
        end

        def find_cycle_by_cutting_date(date)
          cutting_date = calculate_cutting_date_for(date)
          credit_card_cycles.find_by(cutting_date: cutting_date)
        end

        def calculate_cutting_date_for(date)
          # Si la fecha es antes del día de corte del mes actual,
          # pertenece al ciclo anterior
          if date.day < cutting_day
            # Ciclo anterior (mes anterior)
            prev_month = date.beginning_of_month - 1.day
            Date.new(prev_month.year, prev_month.month, cutting_day)
          else
            # Ciclo actual (mes actual)
            Date.new(date.year, date.month, cutting_day)
          end
        rescue ArgumentError
          # Manejar casos como 31 de febrero
          Date.new(date.year, date.month, -1) # Último día del mes
        end

        def recalculate_totals
          # Actualizar balances totales basados en todos los ciclos
          self.update_columns(
            updated_at: Time.current
          )
        end

        def create_history_entry(transaction, cycle)
          # Crear historial referenciando el ciclo específico
          credit_card_histories.create!(
            transaction: transaction,
            credit_card_cycle: cycle,
            pre_balance: cycle.current_balance_was || 0,
            post_balance: cycle.current_balance,
            action_type: transaction.transaction_type_id == income_transaction_type_id ? 'payment' : 'purchase'
          )
        end

        def income_transaction_type_id
          1 # Placeholder
        end

        def expense_transaction_type_id
          2 # Placeholder
        end

    end
  end
end
