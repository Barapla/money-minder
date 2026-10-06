# frozen_string_literal: true

# Presenta el listado de deudas separado en las dos direcciones: lo que me deben
# y lo que debo. Los totales salen de las transacciones ligadas a cada deuda, no
# de un contador guardado.
class DebtsIndexPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(user)
    @user = user
  end

  def any?
    debts.any?
  end

  def receivables
    @receivables ||= debts.select(&:receivable?)
  end

  def payables
    @payables ||= debts.select(&:payable?)
  end

  def owed_to_me
    outstanding_total(receivables)
  end

  def owed_by_me
    outstanding_total(payables)
  end

  # Lo que queda a tu favor una vez cruzadas las dos direcciones.
  def net_position
    owed_to_me - owed_by_me
  end

  def collected_total
    receivables.sum(&:paid_amount)
  end

  def next_due
    @next_due ||= debts.select(&:active?)
                       .filter_map { |debt| [debt, debt.next_due_date] if debt.next_due_date }
                       .min_by(&:last)
  end

  def group_total(list)
    outstanding_total(list)
  end

  def format_currency(amount)
    number_to_currency(amount.to_f, unit: '$')
  end

  private

  attr_reader :user

  def debts
    @debts ||= user.debts
                   .includes(:transactions, :icon, :color, :category, obligatory_payment: :recurrence)
                   .recent_first
                   .to_a
  end

  def outstanding_total(list)
    list.select(&:active?).sum(&:remaining_amount)
  end
end
