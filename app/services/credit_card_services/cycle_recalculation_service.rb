# frozen_string_literal: true

module CreditCardServices
  # Service to recalculate or create a credit card cycle based on transactions and cutting date
  class CycleRecalculationService
    attr_reader :credit_card

    def initialize(credit_card)
      @credit_card = credit_card
    end

    def find_or_create_cycle_for_date(cutting_date)
      out_amount = get_out_amount_transactions_by_date_range(cutting_date - 30.days, cutting_date)
      in_amount = get_in_amount_transactions_by_date_range(cutting_date - 30.days, cutting_date)

      cycle_status = calculate_cycle_status(cutting_date, out_amount, in_amount)

      main_cycle = credit_card.credit_card_cycles.find_or_create_by(cutting_date:) do |cycle|
        initial_debt = cycle.previous_cycle.present? ? 0.0 : credit_card.initial_debt

        cycle.payment_due_date = cutting_date + credit_card.payment_due_days.days
        cycle.cycle_balance = 0
        cycle.historical_balance = cycle.previous_cycle.present? ? cycle.previous_cycle.closing_balance : 0.0
        cycle.closing_balance = cycle.historical_balance + initial_debt
        cycle.purchases = 0
        cycle.payments = 0
        cycle.fees = 0.0

        # Cálculo correcto del pago mínimo
        cycle.minimum_payment = 0

        cycle.interest = 0.0
        cycle.fees = 0.0
        cycle.status = cycle_status
      end

      main_cycle.update(status: cycle_status) if main_cycle.status != cycle_status
      main_cycle
    end

    private

    def calculate_minimum_payment(closing_balance)
      # Si el saldo es 0 o negativo, no hay pago mínimo
      return 0.0 if closing_balance <= 0

      percentage_payment = closing_balance * 0.05 # 5%
      minimum_fixed = 25.0

      # Si el saldo total es menor al mínimo fijo, pagar el saldo total
      if closing_balance < minimum_fixed
        closing_balance
      else
        # Pagar el mayor entre el porcentaje y el mínimo fijo
        [percentage_payment, minimum_fixed].max
      end
    end

    def get_out_amount_transactions_by_date_range(start_date, end_date)
      credit_card.transactions.by_transaction_type(%w[expense
                                                      transaction]).where(transaction_date: start_date..end_date)
    end

    def get_in_amount_transactions_by_date_range(start_date, end_date)
      credit_card.transactions.by_transaction_type(['income']).where(transaction_date: start_date..end_date)
    end

    def calculate_cycle_status(cutting_date, out_amount, in_amount)
      if cutting_date + credit_card.payment_due_days.days < Date.today
        if (out_amount.sum(:amount) - in_amount.sum(:amount)) <= 0
          Status.find_by(code: 'closed')
        else
          Status.find_by(code: 'overdue')
        end
      elsif cutting_date <= Date.today
        Status.find_by(code: 'open')
      elsif (out_amount.sum(:amount) - in_amount.sum(:amount)) <= 0
        Status.find_by(code: 'pending_payment')
      else
        Status.find_by(code: 'closed')
      end
    end
  end
end
