# frozen_string_literal: true

# User model
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  belongs_to :role
  belongs_to :currency, optional: true

  has_many :transactions, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy

  attr_accessor :name

  before_validation :split_name, if: -> { name.present? }

  after_initialize :set_default_role

  private

  def set_default_role
    self.role ||= Role.find_by(name: 'user')
  end

  def split_name
    split = name.split(' ', 2)
    self.first_name = split.first
    self.last_name = split.last || '' # In case there's no last name provided
  end
end
