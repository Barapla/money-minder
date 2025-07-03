# frozen_string_literal: true

# Catalog Model
class Catalog < ApplicationRecord
  belongs_to :group_catalog

  has_many :budgets, dependent: :nullify, foreign_key: 'budget_type_id'
  has_many :budgets, dependent: :nullify, foreign_key: 'color_id'
  has_many :budgets, dependent: :nullify, foreign_key: 'icon_id'

  scope :by_group, lambda { |group_name|
    joins(:group_catalog)
      .where(group_catalogs: { code: group_name })
      .order(:code)
  }

  def self.get_by_group_pluck(group)
    by_group(group).pluck(:value, :id) # Solo carga los campos necesarios
  end
end
