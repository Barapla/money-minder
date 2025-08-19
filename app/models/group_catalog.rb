# frozen_string_literal: true

# GroupCatalog Model
class GroupCatalog < ApplicationRecord
  include Seedable
  has_many :catalogs, class_name: 'Catalog', foreign_key: 'group_catalog_id', dependent: :destroy
  has_many :statuses, class_name: 'Status', foreign_key: 'group_catalog_id', dependent: :destroy
end
