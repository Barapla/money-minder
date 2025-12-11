class CreditScoreEvent < ApplicationRecord
  belongs_to :credit_card
  belongs_to :credit_card_cycle
end
