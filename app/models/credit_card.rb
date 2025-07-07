# frozen_string_literal: true

# == Schema Information
class CreditCard < ApplicationRecord
  belongs_to :budget
end
