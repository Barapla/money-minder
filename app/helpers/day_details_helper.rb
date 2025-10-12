# frozen_string_literal: true

# DayDetailsHelper provides methods for day details functionality.
module DayDetailsHelper
  def transaction_type_label(transaction)
    label = transaction.transaction_type.value
    label += " (Transferencia)" if transaction.income_transfer?
    label
  end
end
