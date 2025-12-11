class CreditCardProduct < ApplicationRecord
  belongs_to :financial_institution
  belongs_to :credit_card_tier
end
