# frozen_string_literal: true

# CreditCardCycleTransaction model
class CreditCardCycleTransaction < ApplicationRecord
  belongs_to :transaction_record, class_name: 'Transaction', foreign_key: 'transaction_id'
  belongs_to :credit_card_cycle
end
