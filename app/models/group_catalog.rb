# frozen_string_literal: true

# GroupCatalog Model
class GroupCatalog < ApplicationRecord
  include Seedable
  # Associations
  has_many :catalogs, class_name: 'Catalog', foreign_key: 'group_catalog_id', dependent: :destroy
  has_many :statuses, class_name: 'Status', foreign_key: 'group_catalog_id', dependent: :destroy

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  def to_s
    name
  end
end
