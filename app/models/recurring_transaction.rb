# frozen_string_literal: true

# RecurringTransaction model
class RecurringTransaction < ApplicationRecord
  belongs_to :category
  belongs_to :user
  belongs_to :currency
end
