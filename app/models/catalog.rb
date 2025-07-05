# frozen_string_literal: true

# Catalog Model
class Catalog < ApplicationRecord
  belongs_to :group_catalog

  has_many :budgets, dependent: :nullify, foreign_key: 'budget_type_id'
  has_many :budgets, dependent: :nullify, foreign_key: 'color_id'
  has_many :budgets, dependent: :nullify, foreign_key: 'icon_id'

  scope :by_group, lambda { |group_name, excepts = []|
    joins(:group_catalog)
      .where(group_catalogs: { code: group_name })
      .order(:code)
      .where.not(code: excepts) # Exclude specific codes if provided
  }

  def self.get_by_group_pluck(group, excepts = [])
    by_group(group, excepts).pluck(:value, :id) # Solo carga los campos necesarios
  end

  def self.seed_unique_keys
    %i[code group_catalog_id]
  end
end
