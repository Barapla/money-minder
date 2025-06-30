# frozen_string_literal: true

# Transaction model
class Transaction < ApplicationRecord
  belongs_to :budget
  belongs_to :category
  belongs_to :currency
  belongs_to :user
end
