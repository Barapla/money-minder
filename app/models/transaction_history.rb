# frozen_string_literal: true

# TransactionHistory Model
class TransactionHistory < ApplicationRecord
  belongs_to :transaction_record, class_name: 'Transaction', foreign_key: 'transaction_id'
end
