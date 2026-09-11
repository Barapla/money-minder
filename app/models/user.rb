# frozen_string_literal: true

# User model
class User < ApplicationRecord
  include Seedable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :confirmable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :role
  belongs_to :currency, optional: true

  has_many :budgets, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy
  has_many :obligatory_payments, dependent: :destroy
  has_many :saving_goals, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_one :employment_information, dependent: :destroy
  has_one :payroll_profile, dependent: :destroy

  attr_accessor :name

  before_validation :split_name, if: -> { name.present? }

  after_initialize :set_default_role
  after_create :create_personal_budget

  def self.seed_unique_keys
    [:email]
  end

  def personal_budget
    budgets.find_by(personal: true)
  end

  def admin?
    role&.name == 'admin'
  end

  private

  def set_default_role
    self.role ||= Role.find_by(name: 'user')
  end

  def create_personal_budget
    return if personal_budget.present?

    Budget.create!(
      name: "Efectivo de #{first_name}",
      budget_type: Catalog.by_group('budget_types').find_by(code: 'cash'),
      icon: Catalog.by_group('budget_icons').find_by(code: 'cash'),
      color: Catalog.by_group('colors').find_by(code: 'purple'),
      personal: true,
      user: self
    )
  end

  def split_name
    split = name.split(' ', 2)
    self.first_name = split.first
    self.last_name = split.last || '' # In case there's no last name provided
  end
end
