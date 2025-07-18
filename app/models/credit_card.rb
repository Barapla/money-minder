# frozen_string_literal: true

# == Schema Information
class CreditCard < ApplicationRecord
  belongs_to :budget

  after_save :set_current_amount, if: :saved_change_to_current_amount?

  def set_current_amount
    budget.update(current_amount: limit_amount - debt_amount)
  end

  private

  def saved_change_to_current_amount?
    saved_change_to_limit_amount? || saved_change_to_debt_amount?
  end
end
