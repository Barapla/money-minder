# frozen_string_literal: true

# Transaction model
class Transaction < ApplicationRecord
  belongs_to :category
  belongs_to :user
  belongs_to :currency
end
